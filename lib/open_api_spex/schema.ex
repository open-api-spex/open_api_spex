defmodule OpenApiSpex.Schema do
  @moduledoc """
  The Schema Object allows the definition of input and output data types. These types can be objects, but also primitives and arrays.

  See https://swagger.io/specification/#schemaObject

  ## Example
      alias OpenApiSpex.Schema

      %Schema{
        title: "User",
        type: :object,
        properties: %{
          id: %Schema{type: :integer, minimum: 1},
          name: %Schema{type: :string, pattern: "[a-zA-Z][a-zA-Z0-9_]+"},
          email: %Scheam{type: :string, format: :email},
          last_login: %Schema{type: :string, format: :"date-time"}
        },
        required: [:name, :email],
        example: %{
          "name" => "joe",
          "email" => "joe@gmail.com"
        }
      }
  """
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
    {:additionalProperties, true},
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

  @doc """
  Cast a simple value to the elixir type defined by a schema.

  By default, object types are cast to maps, however if the "x-struct" attribute is set in the schema,
  the result will be constructed as an instance of the given struct type.

  ## Examples

      iex> OpenApiSpex.Schema.cast(%Schema{type: :integer}, "123", %{})
      {:ok, 123}

      iex> {:ok, dt = %DateTime{}} = OpenApiSpex.Schema.cast(%Schema{type: :string, format: :"date-time"}, "2018-04-02T13:44:55Z", %{})
      ...> dt |> DateTime.to_iso8601()
      "2018-04-02T13:44:55Z"
  """
  @spec cast(Schema.t | Reference.t, any, %{String.t => Schema.t}) :: {:ok, any} | {:error, String.t}
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
  def cast(schema = %Schema{type: :object}, value, schemas) when is_map(value) do
    with {:ok, props} <- cast_properties(schema, Enum.to_list(value), schemas) do
      {:ok, Map.new(props)}
    end
  end
  def cast(ref = %Reference{}, val, schemas), do: cast(Reference.resolve_schema(ref, schemas), val, schemas)
  def cast(additionalProperties, val, _schemas) when additionalProperties in [true, false, nil], do: val

  @spec cast_properties(Schema.t, list, %{String.t => Schema.t}) :: {:ok, list} | {:error, String.t}
  defp cast_properties(%Schema{}, [], _schemas), do: {:ok, []}
  defp cast_properties(object_schema = %Schema{}, [{key, value} | rest], schemas) do
    {name, schema} = Enum.find(
      object_schema.properties,
      {key, object_schema.additionalProperties},
      fn {name, _schema} -> to_string(name) == to_string(key) end)

    with {:ok, new_value} <- cast(schema, value, schemas),
         {:ok, cast_tail} <- cast_properties(object_schema, rest, schemas) do
      {:ok, [{name, new_value} | cast_tail]}
    end
  end


  @doc """
  Validate a value against a Schema.

  This expects that the value has already been `cast` to the appropriate data type.

  ## Examples

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :integer, minimum: 5}, 3, %{})
      {:error, "3 is smaller than minimum 5"}

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :string, pattern: "(.*)@(.*)"}, "joe@gmail.com", %{})
      :ok

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :string, pattern: "(.*)@(.*)"}, "joegmail.com", %{})
      {:error, "Value does not match pattern: (.*)@(.*)"}
  """
  @spec validate(Schema.t | Reference.t, any, %{String.t => Schema.t}) :: :ok | {:error, String.t}
  def validate(ref = %Reference{}, val, schemas), do: validate(Reference.resolve_schema(ref, schemas), val, schemas)
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

  @spec validate_multiple(Schema.t, number) :: :ok | {:error, String.t}
  defp validate_multiple(%{multipleOf: nil}, _), do: :ok
  defp validate_multiple(%{multipleOf: n}, value) when (round(value / n) * n == value), do: :ok
  defp validate_multiple(%{multipleOf: n}, value), do: {:error, "#{value} is not a multiple of #{n}"}

  @spec validate_maximum(Schema.t, number) :: :ok | {:error, String.t}
  defp validate_maximum(%{maximum: nil}, _), do: :ok
  defp validate_maximum(%{maximum: n, exclusiveMaximum: true}, value) when value < n, do: :ok
  defp validate_maximum(%{maximum: n}, value) when value <= n, do: :ok
  defp validate_maximum(%{maximum: n}, value), do: {:error, "#{value} is larger than maximum #{n}"}

  @spec validate_minimum(Schema.t, number) :: :ok | {:error, String.t}
  defp validate_minimum(%{minimum: nil}, _), do: :ok
  defp validate_minimum(%{minimum: n, exclusiveMinimum: true}, value) when value > n, do: :ok
  defp validate_minimum(%{minimum: n}, value) when value >= n, do: :ok
  defp validate_minimum(%{minimum: n}, value), do: {:error, "#{value} is smaller than minimum #{n}"}

  @spec validate_max_length(Schema.t, String.t) :: :ok | {:error, String.t}
  defp validate_max_length(%{maxLength: nil}, _), do: :ok
  defp validate_max_length(%{maxLength: n}, value) do
    case String.length(value) <= n do
      true -> :ok
      _ -> {:error, "String length is larger than maxLength: #{n}"}
    end
  end

  @spec validate_min_length(Schema.t, String.t) :: :ok | {:error, String.t}
  defp validate_min_length(%{minLength: nil}, _), do: :ok
  defp validate_min_length(%{minLength: n}, value) do
    case String.length(value) >= n do
      true -> :ok
      _ -> {:error, "String length is smaller than minLength: #{n}"}
    end
  end

  @spec validate_max_length(Schema.t, String.t) :: :ok | {:error, String.t}
  defp validate_pattern(%{pattern: nil}, _), do: :ok
  defp validate_pattern(schema = %{pattern: regex}, val) when is_binary(regex) do
    with {:ok, regex} <- Regex.compile(regex) do
      validate_pattern(%{schema | pattern: regex}, val)
    end
  end
  defp validate_pattern(%{pattern: regex = %Regex{}}, val) do
    case Regex.match?(regex, val) do
      true -> :ok
      _ -> {:error, "Value does not match pattern: #{regex.source}"}
    end
  end

  @spec validate_max_length(Schema.t, list) :: :ok | {:error, String.t}
  defp validate_max_items(%Schema{maxItems: nil}, _), do: :ok
  defp validate_max_items(%Schema{maxItems: n}, value) when length(value) <= n, do: :ok
  defp validate_max_items(%Schema{maxItems: n}, value) do
    {:error, "Array length #{length(value)} is larger than maxItems: #{n}"}
  end

  @spec validate_min_items(Schema.t, list) :: :ok | {:error, String.t}
  defp validate_min_items(%Schema{minItems: nil}, _), do: :ok
  defp validate_min_items(%Schema{minItems: n}, value) when length(value) >= n, do: :ok
  defp validate_min_items(%Schema{minItems: n}, value) do
    {:error, "Array length #{length(value)} is smaller than minItems: #{n}"}
  end

  @spec validate_unique_items(Schema.t, list) :: :ok | {:error, String.t}
  defp validate_unique_items(%Schema{uniqueItems: true}, value) do
    unique_size =
      value
      |> MapSet.new()
      |> MapSet.size()

    case unique_size == length(value) do
      true -> :ok
      _ -> {:error, "Array items must be unique"}
    end
  end
  defp validate_unique_items(_, _), do: :ok

  @spec validate_array_items(Schema.t, list, %{String.t => Schema.t}) :: :ok | {:error, String.t}
  defp validate_array_items(%Schema{type: :array, items: nil}, value, _schemas) when is_list(value), do: :ok
  defp validate_array_items(%Schema{type: :array}, [], _schemas), do: :ok
  defp validate_array_items(schema = %Schema{type: :array, items: item_schema}, [x | rest], schemas) do
    with :ok <- validate(item_schema, x, schemas) do
      validate(schema, rest, schemas)
    end
  end

  @spec validate_required_properties(Schema.t, %{}) :: :ok | {:error, String.t}
  defp validate_required_properties(%Schema{type: :object, required: nil}, _), do: :ok
  defp validate_required_properties(%Schema{type: :object, required: required}, value) do
    missing = required -- Map.keys(value)
    case missing do
      [] -> :ok
      _ -> {:error, "Missing required properties: #{inspect(missing)}"}
    end
  end

  @spec validate_max_properties(Schema.t, %{}) :: :ok | {:error, String.t}
  defp validate_max_properties(%Schema{type: :object, maxProperties: nil}, _), do: :ok
  defp validate_max_properties(%Schema{type: :object, maxProperties: n}, val) when map_size(val) <= n, do: :ok
  defp validate_max_properties(%Schema{type: :object, maxProperties: n}, val) do
    {:error, "Object property count #{map_size(val)} is greater than maxProperties: #{n}"}
  end

  @spec validate_min_properties(Schema.t, %{}) :: :ok | {:error, String.t}
  defp validate_min_properties(%Schema{type: :object, minProperties: nil}, _), do: :ok
  defp validate_min_properties(%Schema{type: :object, minProperties: n}, val) when map_size(val) >= n, do: :ok
  defp validate_min_properties(%Schema{type: :object, minProperties: n}, val) do
    {:error, "Object property count #{map_size(val)} is less than minProperties: #{n}"}
  end

  @spec validate_min_properties(Schema.t, %{}) :: :ok | {:error, String.t}
  defp validate_object_properties(properties = %{}, value, schemas) do
    properties
    |> Enum.filter(fn {name, _schema} -> Map.has_key?(value, name) end)
    |> validate_object_properties(value, schemas)
  end
  defp validate_object_properties([], _, _), do: :ok
  defp validate_object_properties([{name, schema} | rest], value, schemas) do
    case validate(schema, Map.fetch!(value, name), schemas) do
      :ok -> validate_object_properties(rest, value, schemas)
      error -> error
    end
  end
end