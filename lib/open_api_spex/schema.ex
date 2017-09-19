defmodule OpenApiSpex.Schema do
  alias OpenApiSpex.{
    Schema, Reference, Discriminator, Xml, ExternalDocumentation
  }

  defstruct [
    :title,
    :multipleOf,
    :maximum,
    :exclusiveMaximum,
    :minimum,
    :exclusiveMinimum,
    :maxLength,
    :minLength,
    :pattern,
    :maxItems,
    :minItems,
    :uniqueItems,
    :maxProperties,
    :minProperties,
    :required,
    :enum,
    :type,
    :allOf,
    :oneOf,
    :anyOf,
    :not,
    :items,
    :properties,
    :additionalProperties,
    :description,
    :format,
    :default,
    :nullable,
    :discriminator,
    :readOnly,
    :writeOnly,
    :xml,
    :externalDocs,
    :example,
    :deprecated,
    :"x-struct"
  ]
  @type t :: %__MODULE__{
    title: String.t,
    multipleOf: number,
    maximum: number,
    exclusiveMaximum: boolean,
    minimum: number,
    exclusiveMinimum: boolean,
    maxLength: integer,
    minLength: integer,
    pattern: String.t,
    maxItems: integer,
    minItems: integer,
    uniqueItems: boolean,
    maxProperties: integer,
    minProperties: integer,
    required: [String.t],
    enum: [String.t],
    type: String.t,
    allOf: [Schema.t | Reference.t],
    oneOf: [Schema.t | Reference.t],
    anyOf: [Schema.t | Reference.t],
    not: Schema.t | Reference.t,
    items: Schema.t | Reference.t,
    properties: %{String.t => Schema.t | Reference.t},
    additionalProperties: boolean | Schema.t | Reference.t,
    description: String.t,
    format: String.t,
    default: any,
    nullable: boolean,
    discriminator: Discriminator.t,
    readOnly: boolean,
    writeOnly: boolean,
    xml: Xml.t,
    externalDocs: ExternalDocumentation.t,
    example: any,
    deprecated: boolean,
    "x-struct": module
  }

  def resolve_schema(schema = %Schema{}, _), do: schema
  def resolve_schema(%Reference{"$ref": "#/components/schemas/" <> name}, schemas), do: schemas[name]

  def cast(schema = %Schema{"x-struct": mod}, value, schemas) when not is_nil(mod) do
    with {:ok, data} <- cast(%{schema | "x-struct": nil}, value, schemas) do
      {:ok, struct(mod, data)}
    end
  end

  def cast(%Schema{type: :boolean}, value, _schemas) when is_boolean(value), do: {:ok, value}
  def cast(%Schema{type: :boolean}, value, _schemas) when is_binary(value) do
    case value do
      "true" -> true
      "false" -> false
      _ -> {:error, "Invalid boolean: #{inspect(value)}"}
    end
  end
  def cast(%Schema{type: :integer}, value, _schemas) when is_integer(value), do: {:ok, value}
  def cast(%Schema{type: :integer}, value, _schemas) when is_binary(value) do
    case Integer.parse(value) do
      {i, ""} -> {:ok, i}
      _ -> {:error, :bad_integer}
    end
  end
  def cast(%Schema{type: :number}, value, _schemas) when is_number(value), do: {:ok, value}
  def cast(%Schema{type: :number}, value, _schemas) when is_binary(value) do
    case Float.parse(value) do
      {x, ""} -> {:ok, x}
      _ -> {:error, :bad_float}
    end
  end
  def cast(%Schema{type: :string, format: :"date-time"}, value, _schemas) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime = %DateTime{}, _offset} -> {:ok, datetime}
      error = {:error, _reason} -> error
    end
  end
  def cast(%Schema{type: :string, format: :date}, value, _schemas) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date = %Date{}} -> {:ok, date}
      error = {:error, _reason} -> error
    end
  end
  def cast(%Schema{type: :string}, value, _schemas) when is_binary(value), do: {:ok, value}
  def cast(%Schema{type: :array, items: nil}, value, _schemas) when is_list(value), do: {:ok, value}
  def cast(%Schema{type: :array}, [], _schemas), do: {:ok, []}
  def cast(schema = %Schema{type: :array, items: items_schema}, [x | rest], schemas) do
    with {:ok, x_cast} <- cast(items_schema, x, schemas),
         {:ok, rest_cast} <- cast(schema, rest, schemas) do
      {:ok, [x_cast | rest_cast]}
    end
  end
  def cast(%Schema{type: :object, properties: properties}, value, schemas) when is_map(value) do
    properties
    |> Stream.filter(fn {name, _} -> Map.has_key?(value, name) || Map.has_key?(value, Atom.to_string(name)) end)
    |> Stream.map(fn {name, schema} -> {name, resolve_schema(schema, schemas)} end)
    |> Stream.map(fn {name, schema} -> {name, schema, Map.get(value, name, value[Atom.to_string(name)])} end)
    |> Stream.map(fn {name, schema, property_val} -> cast_property(name, schema, property_val, schemas) end)
    |> Enum.reduce({:ok, %{}}, fn
         _, {:error, reason} -> {:error, reason}
         {:error, reason}, _ -> {:error, reason}
         {:ok, {name, property_val}}, {:ok, acc} -> {:ok, Map.put(acc, name, property_val)}
       end)
  end
  def cast(ref = %Reference{}, val, schemas), do: cast(resolve_schema(ref, schemas), val, schemas)

  defp cast_property(name, schema, value, schemas) do
    casted = cast(schema, value, schemas)
    case casted do
      {:ok, new_value} -> {:ok, {name, new_value}}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate(ref = %Reference{}, val, schemas), do: validate(resolve_schema(ref, schemas), val, schemas)
  def validate(schema = %Schema{type: type}, value, _schemas) when type in [:integer, :number] do
    with :ok <- validate_multiple(schema, value),
         :ok <- validate_maximum(schema, value),
         :ok <- validate_minimum(schema, value) do
      :ok
    end
  end
  def validate(schema = %Schema{type: :string}, value, _schemas) do
    with :ok <- validate_max_length(schema, value),
         :ok <- validate_min_length(schema, value),
         :ok <- validate_pattern(schema, value) do
      :ok
    end
  end
  def validate(%Schema{type: :boolean}, value, _schemas) do
    case is_boolean(value) do
      true -> :ok
      _ -> {:error, "Invalid boolean: #{inspect(value)}"}
    end
  end
  def validate(schema = %Schema{type: :array}, value, schemas) do
    with :ok <- validate_max_items(schema, value),
         :ok <- validate_min_items(schema, value),
         :ok <- validate_unique_items(schema, value),
         :ok <- validate_array_items(schema, value, schemas) do
      :ok
    end
  end
  def validate(schema = %Schema{type: :object, properties: properties}, value, schemas) do
    with :ok <- validate_required_properties(schema, value),
         :ok <- validate_max_properties(schema, value),
         :ok <- validate_min_properties(schema, value),
         :ok <- validate_object_properties(properties, value, schemas) do
      :ok
    end
  end

  def validate_multiple(%{multipleOf: nil}, _), do: :ok
  def validate_multiple(%{multipleOf: n}, value) when (round(value / n) * n == value), do: :ok
  def validate_multiple(%{multipleOf: n}, value), do: {:error, "#{value} is not a multiple of #{n}"}

  def validate_maximum(%{maximum: nil}, _), do: :ok
  def validate_maximum(%{maximum: n, exclusiveMaximum: true}, value) when value < n, do: :ok
  def validate_maximum(%{maximum: n}, value) when value <= n, do: :ok
  def validate_maximum(%{maximum: n}, value), do: {:error, "#{value} is larger than maximum #{n}"}

  def validate_minimum(%{minimum: nil}, _), do: :ok
  def validate_minimum(%{minimum: n, exclusiveMinimum: true}, value) when value > n, do: :ok
  def validate_minimum(%{minimum: n}, value) when value >= n, do: :ok
  def validate_minimum(%{minimum: n}, value), do: {:error, "#{value} is smaller than minimum #{n}"}

  def validate_max_length(%{maxLength: nil}, _), do: :ok
  def validate_max_length(%{maxLength: n}, value) do
    case String.length(value) <= n do
      true -> :ok
      _ -> {:error, "String length is larger than maxLength: #{n}"}
    end
  end

  def validate_min_length(%{minLength: nil}, _), do: :ok
  def validate_min_length(%{minLength: n}, value) do
    case String.length(value) >= n do
      true -> :ok
      _ -> {:error, "String length is smaller than minLength: #{n}"}
    end
  end

  def validate_pattern(%{pattern: nil}, _), do: :ok
  def validate_pattern(schema = %{pattern: regex}, val) when is_binary(regex) do
    validate_pattern(%{schema | pattern: Regex.compile(regex)}, val)
  end
  def validate_pattern(%{pattern: regex = %Regex{}}, val) do
    case Regex.match?(regex, val) do
      true -> :ok
      _ -> {:error, "Value does not match pattern: #{regex.source}"}
    end
  end

  def validate_max_items(%Schema{maxItems: nil}, _), do: :ok
  def validate_max_items(%Schema{maxItems: n}, value) when length(value) <= n, do: :ok
  def validate_max_items(%Schema{maxItems: n}, value) do
    {:error, "Array length #{length(value)} is larger than maxItems: #{n}"}
  end

  def validate_min_items(%Schema{minItems: nil}, _), do: :ok
  def validate_min_items(%Schema{minItems: n}, value) when length(value) >= n, do: :ok
  def validate_min_items(%Schema{minItems: n}, value) do
    {:error, "Array length #{length(value)} is smaller than minItems: #{n}"}
  end

  def validate_unique_items(%Schema{uniqueItems: true}, value) do
    unique_size =
      value
      |> MapSet.new()
      |> MapSet.size()

    case unique_size == length(value) do
      true -> :ok
      _ -> {:error, "Array items must be unique"}
    end
  end
  def validate_unique_items(_, _), do: :ok

  def validate_array_items(%Schema{type: :array, items: nil}, value, _schemas) when is_list(value), do: :ok
  def validate_array_items(%Schema{type: :array}, [], _schemas), do: :ok
  def validate_array_items(schema = %Schema{type: :array, items: item_schema}, [x | rest], schemas) do
    with :ok <- validate(item_schema, x, schemas) do
      validate(schema, rest, schemas)
    end
  end

  def validate_required_properties(%Schema{type: :object, required: nil}, _), do: :ok
  def validate_required_properties(%Schema{type: :object, required: required}, value) do
    missing = required -- Map.keys(value)
    case missing do
      [] -> :ok
      _ -> {:error, "Missing required properties: #{inspect(missing)}"}
    end
  end

  def validate_max_properties(%Schema{type: :object, maxProperties: nil}, _), do: :ok
  def validate_max_properties(%Schema{type: :object, maxProperties: n}, val) when map_size(val) <= n, do: :ok
  def validate_max_properties(%Schema{type: :object, maxProperties: n}, val) do
    {:error, "Object property count #{map_size(val)} is greater than maxProperties: #{n}"}
  end

  def validate_min_properties(%Schema{type: :object, minProperties: nil}, _), do: :ok
  def validate_min_properties(%Schema{type: :object, minProperties: n}, val) when map_size(val) >= n, do: :ok
  def validate_min_properties(%Schema{type: :object, minProperties: n}, val) do
    {:error, "Object property count #{map_size(val)} is less than minProperties: #{n}"}
  end

  def validate_object_properties(properties = %{}, value, schemas) do
    properties
    |> Enum.filter(fn {name, _schema} -> Map.has_key?(value, name) end)
    |> validate_object_properties(value, schemas)
  end
  def validate_object_properties([], _, _), do: :ok
  def validate_object_properties([{name, schema} | rest], value, schemas) do
    case validate(schema, Map.fetch!(value, name), schemas) do
      :ok -> validate_object_properties(rest, value, schemas)
      error -> error
    end
  end
end