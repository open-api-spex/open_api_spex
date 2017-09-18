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
    :deprecated
  ]
  @type t :: %__MODULE__{
    title: String.t,
    multipleOf: number,
    maximum: number,
    exclusiveMaximum: number,
    minimum: number,
    exclusiveMinimum: number,
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
    deprecated: boolean
  }

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

  defp resolve_schema(schema = %Schema{}, _), do: schema
  defp resolve_schema(%Reference{"$ref": "#/components/schemas/" <> name}, schemas), do: schemas[name]

  defp cast_property(name, schema, value, schemas) do
    casted = cast(schema, value, schemas)
    case casted do
      {:ok, new_value} -> {:ok, {name, new_value}}
      {:error, reason} -> {:error, reason}
    end
  end
end