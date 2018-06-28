defmodule OpenApiSpex.Schema do
  @moduledoc """
  Defines the `OpenApiSpex.Schema.t` type and operations for casting and validating against a schema.
  """

  alias OpenApiSpex.{
    Schema, Reference, Discriminator, Xml, ExternalDocumentation
  }

  @doc """
  A module implementing the `OpenApiSpex.Schema` behaviour should export a `schema/0` function
  that produces an `OpenApiSpex.Schema` struct.
  """
  @callback schema() :: t

  @enforce_keys :type
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

  @typedoc """
  [Schema Object](https://swagger.io/specification/#schemaObject)

  The Schema Object allows the definition of input and output data types.
  These types can be objects, but also primitives and arrays.
  This object is an extended subset of the JSON Schema Specification Wright Draft 00.

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
  @type t :: %__MODULE__{
    title: String.t | nil,
    multipleOf: number | nil,
    maximum: number | nil,
    exclusiveMaximum: boolean | nil,
    minimum: number | nil,
    exclusiveMinimum: boolean | nil,
    maxLength: integer | nil,
    minLength: integer | nil,
    pattern: String.t | Regex.t | nil,
    maxItems: integer | nil,
    minItems: integer | nil,
    uniqueItems: boolean | nil,
    maxProperties: integer | nil,
    minProperties: integer | nil,
    required: [atom] | nil,
    enum: [String.t] | nil,
    type: atom,
    allOf: [Schema.t | Reference.t | module] | nil,
    oneOf: [Schema.t | Reference.t | module] | nil,
    anyOf: [Schema.t | Reference.t | module] | nil,
    not: Schema.t | Reference.t | module | nil,
    items: Schema.t | Reference.t | module | nil,
    properties: %{atom => Schema.t | Reference.t | module} | nil,
    additionalProperties: boolean | Schema.t | Reference.t | module | nil,
    description: String.t | nil,
    format: String.t | nil,
    default: any,
    nullable: boolean | nil,
    discriminator: Discriminator.t | nil,
    readOnly: boolean | nil,
    writeOnly: boolean | nil,
    xml: Xml.t | nil,
    externalDocs: ExternalDocumentation.t | nil,
    example: any,
    deprecated: boolean | nil,
    "x-struct": module | nil
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
  @spec cast(Schema.t | Reference.t, any, %{String.t => Schema.t | Reference.t}) :: {:ok, any} | {:error, String.t}
  def cast(schema = %Schema{"x-struct": mod}, value, schemas) when not is_nil(mod) do
    with {:ok, data} <- cast(%{schema | "x-struct": nil}, value, schemas) do
      case data do
        %{__struct__: _} -> {:ok, data}
        _ -> {:ok, struct(mod, data)}
      end
    end
  end
  def cast(%Schema{type: :boolean}, value, _schemas) when is_boolean(value), do: {:ok, value}
  def cast(%Schema{type: :boolean}, value, _schemas) when is_binary(value) do
    case value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
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
  def cast(%Schema{type: :array}, value, _schemas) when not is_list(value) do
    {:error, "Invalid array: #{inspect(value)}"}
  end
  def cast(schema = %Schema{type: :object, discriminator: discriminator = %{}}, value = %{}, schemas) do
    with {:ok, value} <- tag(schema, value),
         {:ok, derived_schema} <- Discriminator.resolve(discriminator, value, schemas),
         {:ok, result} <- cast(derived_schema, value, schemas) do
      {:ok, untag(schema, result)}
    else
      {:error, :already_tagged} -> cast(%{schema | discriminator: nil}, value, schemas)
      {:error, reason} -> {:error, reason}
    end
  end
  def cast(%Schema{type: :object, allOf: [x | rest]}, value = %{}, schemas) do
    with {:ok, cast_x} <- cast(x, value, schemas),
         {:ok, cast_rest} <- cast(rest, value, schemas) do
      Map.merge(cast_x, cast_rest)
    end
  end
  def cast(schema = %Schema{type: :object, allOf: []}, value = %{}, schemas) do
    cast(%{schema | allOf: nil}, value, schemas)
  end
  def cast(schema = %Schema{type: :object}, value, schemas) when is_map(value) do
    schema = %{schema | properties: schema.properties || %{}}
    regular_properties = Enum.filter(value, fn {k, _v} -> is_binary(k) end)
    with {:ok, props} <- cast_properties(schema, regular_properties, schemas) do
      {:ok, Map.new(props)}
    end
  end
  def cast(ref = %Reference{}, val, schemas), do: cast(Reference.resolve_schema(ref, schemas), val, schemas)
  def cast(_additionalProperties = false, val, _schemas) do
    {:error, "Unexpected field with value #{inspect(val)}"}
  end
  def cast(_additionalProperties, val, _schemas), do: {:ok, val}

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

  # Record that a schema has already been used for casting/validation on a value
  @spec tag(Schema.t, map) :: {:ok, map} | {:error, :already_tagged}
  defp tag(schema, value) do
    value = Map.put_new(value, :__open_api_spex_tags, [])
    tags = value.__open_api_spex_tags
    if schema.title in tags do
      {:error, :already_tagged}
    else
      {:ok, %{value | __open_api_spex_tags: [schema.title | tags]}}
    end
  end

  # Remove previously recorded tag
  @spec untag(Schema.t, map) :: map
  defp untag(schema, value) do
    tags = value.__open_api_spex_tags -- [schema.title]
    if Enum.empty?(tags) do
      Map.delete(value, :__open_api_spex_tags)
    else
      Map.put(value, :__open_api_spex_tags, tags)
    end
  end


  @doc """
  Validate a value against a Schema.

  This expects that the value has already been `cast` to the appropriate data type.

  ## Examples

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :integer, minimum: 5}, 3, %{})
      {:error, "#: 3 is smaller than minimum 5"}

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :string, pattern: "(.*)@(.*)"}, "joe@gmail.com", %{})
      :ok

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :string, pattern: "(.*)@(.*)"}, "joegmail.com", %{})
      {:error, "#: Value does not match pattern: (.*)@(.*)"}
  """
  @spec validate(Schema.t | Reference.t, any, %{String.t => Schema.t | Reference.t}) :: :ok | {:error, String.t}
  def validate(schema, val, schemas), do: validate(schema, val, "#", schemas)

  @spec validate(Schema.t | Reference.t, any, String.t, %{String.t => Schema.t | Reference.t}) :: :ok | {:error, String.t}
  def validate(ref = %Reference{}, val, path, schemas), do: validate(Reference.resolve_schema(ref, schemas), val, path, schemas)
  def validate(%Schema{nullable: true}, nil, _path, _schemas), do: :ok
  def validate(%Schema{type: type}, nil, path, _schemas) do
    {:error, "#{path}: null value where #{type} expected"}
  end
  def validate(schema = %Schema{type: type}, value, path, _schemas) when type in [:integer, :number] do
    with :ok <- validate_multiple(schema, value, path),
         :ok <- validate_maximum(schema, value, path),
         :ok <- validate_minimum(schema, value, path) do
      :ok
    end
  end
  def validate(schema = %Schema{type: :string}, value, path, _schemas) do
    with :ok <- validate_max_length(schema, value, path),
         :ok <- validate_min_length(schema, value, path),
         :ok <- validate_pattern(schema, value, path) do
      :ok
    end
  end
  def validate(%Schema{type: :boolean}, value, path, _schemas) do
    case is_boolean(value) do
      true -> :ok
      _ -> {:error, "#{path}: Invalid boolean: #{inspect(value)}"}
    end
  end
  def validate(schema = %Schema{type: :array}, value, path, schemas) do
    with :ok <- validate_max_items(schema, value, path),
         :ok <- validate_min_items(schema, value, path),
         :ok <- validate_unique_items(schema, value, path),
         :ok <- validate_array_items(schema, value, {path, 0}, schemas) do
      :ok
    end
  end
  def validate(schema = %Schema{type: :object}, value = %{}, path, schemas) do
    schema = %{schema | properties: schema.properties || %{}, required: schema.required || []}
    with :ok <- validate_required_properties(schema, value, path),
         :ok <- validate_max_properties(schema, value, path),
         :ok <- validate_min_properties(schema, value, path),
         :ok <- validate_object_properties(schema.properties, MapSet.new(schema.required), value, path, schemas) do
      :ok
    end
  end

  @spec validate_multiple(Schema.t, number, String.t) :: :ok | {:error, String.t}
  defp validate_multiple(%{multipleOf: nil}, _, _), do: :ok
  defp validate_multiple(%{multipleOf: n}, value, _) when (round(value / n) * n == value), do: :ok
  defp validate_multiple(%{multipleOf: n}, value, path), do: {:error, "#{path}: #{value} is not a multiple of #{n}"}

  @spec validate_maximum(Schema.t, number, String.t) :: :ok | {:error, String.t}
  defp validate_maximum(%{maximum: nil}, _val, _path), do: :ok
  defp validate_maximum(%{maximum: n, exclusiveMaximum: true}, value, _path) when value < n, do: :ok
  defp validate_maximum(%{maximum: n}, value, _path) when value <= n, do: :ok
  defp validate_maximum(%{maximum: n}, value, path), do: {:error, "#{path}: #{value} is larger than maximum #{n}"}

  @spec validate_minimum(Schema.t, number, String.t) :: :ok | {:error, String.t}
  defp validate_minimum(%{minimum: nil}, _val, _path), do: :ok
  defp validate_minimum(%{minimum: n, exclusiveMinimum: true}, value, _path) when value > n, do: :ok
  defp validate_minimum(%{minimum: n}, value, _path) when value >= n, do: :ok
  defp validate_minimum(%{minimum: n}, value, path), do: {:error, "#{path}: #{value} is smaller than minimum #{n}"}

  @spec validate_max_length(Schema.t, String.t, String.t) :: :ok | {:error, String.t}
  defp validate_max_length(%{maxLength: nil}, _val, _path), do: :ok
  defp validate_max_length(%{maxLength: n}, value, path) do
    case String.length(value) <= n do
      true -> :ok
      _ -> {:error, "#{path}: String length is larger than maxLength: #{n}"}
    end
  end

  @spec validate_min_length(Schema.t, String.t, String.t) :: :ok | {:error, String.t}
  defp validate_min_length(%{minLength: nil}, _val, _path), do: :ok
  defp validate_min_length(%{minLength: n}, value, path) do
    case String.length(value) >= n do
      true -> :ok
      _ -> {:error, "#{path}: String length is smaller than minLength: #{n}"}
    end
  end

  @spec validate_pattern(Schema.t, String.t, String.t) :: :ok | {:error, String.t}
  defp validate_pattern(%{pattern: nil}, _val, _path), do: :ok
  defp validate_pattern(schema = %{pattern: regex}, val, path) when is_binary(regex) do
    with {:ok, regex} <- Regex.compile(regex) do
      validate_pattern(%{schema | pattern: regex}, val, path)
    end
  end
  defp validate_pattern(%{pattern: regex = %Regex{}}, val, path) do
    case Regex.match?(regex, val) do
      true -> :ok
      _ -> {:error, "#{path}: Value does not match pattern: #{regex.source}"}
    end
  end

  @spec validate_max_items(Schema.t, list, String.t) :: :ok | {:error, String.t}
  defp validate_max_items(%Schema{maxItems: nil}, _val, _path), do: :ok
  defp validate_max_items(%Schema{maxItems: n}, value, _path) when length(value) <= n, do: :ok
  defp validate_max_items(%Schema{maxItems: n}, value, path) do
    {:error, "#{path}: Array length #{length(value)} is larger than maxItems: #{n}"}
  end

  @spec validate_min_items(Schema.t, list, String.t) :: :ok | {:error, String.t}
  defp validate_min_items(%Schema{minItems: nil}, _val, _path), do: :ok
  defp validate_min_items(%Schema{minItems: n}, value, _path) when length(value) >= n, do: :ok
  defp validate_min_items(%Schema{minItems: n}, value, path) do
    {:error, "#{path}: Array length #{length(value)} is smaller than minItems: #{n}"}
  end

  @spec validate_unique_items(Schema.t, list, String.t) :: :ok | {:error, String.t}
  defp validate_unique_items(%Schema{uniqueItems: true}, value, path) do
    unique_size =
      value
      |> MapSet.new()
      |> MapSet.size()

    case unique_size == length(value) do
      true -> :ok
      _ -> {:error, "#{path}: Array items must be unique"}
    end
  end
  defp validate_unique_items(_schema, _value, _path), do: :ok

  @spec validate_array_items(Schema.t, list, {String.t, integer}, %{String.t => Schema.t}) :: :ok | {:error, String.t}
  defp validate_array_items(%Schema{type: :array, items: nil}, value, _path, _schemas) when is_list(value), do: :ok
  defp validate_array_items(%Schema{type: :array}, [], _path, _schemas), do: :ok
  defp validate_array_items(schema = %Schema{type: :array, items: item_schema}, [x | rest], {path, index}, schemas) do
    with :ok <- validate(item_schema, x, "#{path}/#{index}", schemas) do
      validate_array_items(schema, rest, {path, index + 1}, schemas)
    end
  end

  @spec validate_required_properties(Schema.t, %{}, String.t) :: :ok | {:error, String.t}
  defp validate_required_properties(%Schema{type: :object, required: nil}, _val, _path), do: :ok
  defp validate_required_properties(%Schema{type: :object, required: required}, value = %{}, path) do
    missing = required -- Map.keys(value)
    case missing do
      [] -> :ok
      _ -> {:error, "#{path}: Missing required properties: #{inspect(missing)}"}
    end
  end

  @spec validate_max_properties(Schema.t, %{}, String.t) :: :ok | {:error, String.t}
  defp validate_max_properties(%Schema{type: :object, maxProperties: nil}, _val, _path), do: :ok
  defp validate_max_properties(%Schema{type: :object, maxProperties: n}, val, _path) when map_size(val) <= n, do: :ok
  defp validate_max_properties(%Schema{type: :object, maxProperties: n}, val, path) do
    {:error, "#{path}: Object property count #{map_size(val)} is greater than maxProperties: #{n}"}
  end

  @spec validate_min_properties(Schema.t, %{}, String.t) :: :ok | {:error, String.t}
  defp validate_min_properties(%Schema{type: :object, minProperties: nil}, _val, _path), do: :ok
  defp validate_min_properties(%Schema{type: :object, minProperties: n}, val, _path) when map_size(val) >= n, do: :ok
  defp validate_min_properties(%Schema{type: :object, minProperties: n}, val, path) do
    {:error, "#{path}: Object property count #{map_size(val)} is less than minProperties: #{n}"}
  end

  @spec validate_object_properties(Enumerable.t, MapSet.t, %{}, String.t, %{String.t => Schema.t | Reference.t}) :: :ok | {:error, String.t}
  defp validate_object_properties(properties = %{}, required, value = %{}, path, schemas = %{}) do
    properties
    |> Enum.filter(fn {name, _schema} -> Map.has_key?(value, name) end)
    |> validate_object_properties(required, value, path, schemas)
  end
  defp validate_object_properties([], _required, _val, _path, _schemas), do: :ok
  defp validate_object_properties([{name, schema} | rest], required, value = %{}, path, schemas = %{}) do
    property_required = MapSet.member?(required, name)
    property_value = Map.get(value, name)
    property_path = "#{path}/#{name}"
    with :ok <- validate_object_property(schema, property_required, property_value, property_path, schemas),
         :ok <- validate_object_properties(rest, required, value, path, schemas) do
      :ok
    end
  end
  defp validate_object_property(_schema, false, nil, _path, _schemas), do: :ok
  defp validate_object_property(schema, _required, value, path, schemas) do
    validate(schema, value, path, schemas)
  end
end
