defmodule OpenApiSpex.Schema do
  @moduledoc """
  Defines the `OpenApiSpex.Schema.t` type and operations for casting and validating against a schema.

  The `OpenApiSpex.schema` macro can be used to declare schemas with an associated struct and JSON Encoder.

  ## Examples

      defmodule MyApp.Schemas do
        defmodule EmailString do
          @behaviour OpenApiSpex.Schema
          def schema do
            %OpenApiSpex.Schema {
              title: "EmailString",
              type: :string,
              format: :email
            }
          end
        end

        defmodule Person do
          require OpenApiSpex
          alias OpenApiSpex.{Reference, Schema}

          OpenApiSpex.schema(%{
            type: :object,
            required: [:name],
            properties: %{
              name: %Schema{type: :string},
              address: %Reference{"$ref": "#/components/schemas/Address"},
              age: %Schema{type: :integer, format: :int32, minimum: 0}
            }
          })
        end

        defmodule StringDictionary do
          @behaviour OpenApiSpex.Schema

          def schema() do
            %OpenApiSpex.Schema{
              type: :object,
              additionalProperties: %OpenApiSpex.Schema{
                type: :string
              }
            }
          end
        end

        defmodule PetCommon do
          require OpenApiSpex
          alias OpenApiSpex.{Schema, Discriminator}
          OpenApiSpex.schema(%{
            title: "PetCommon",
            description: "Properties common to all Pets",
            type: :object,
            properties: %{
              name: %Schema{type: :string},
              petType: %Schema{type: :string}
            },
            required: [:name, :petType]
          })
        end

        defmodule Cat do
          require OpenApiSpex
          alias OpenApiSpex.Schema
          OpenApiSpex.schema(%{
            title: "Cat",
            type: :object,
            description: "A representation of a cat. Note that `Cat` will be used as the discriminator value.",
            allOf: [
              PetCommon,
              %Schema{
                type: :object,
                properties: %{
                  huntingSkill: %Schema{
                    type: :string,
                    description: "The measured skill for hunting",
                    default: "lazy",
                    enum: ["clueless", "lazy", "adventurous", "aggressive"]
                  }
                },
                required: [:huntingSkill]
              }
            ]
          })
        end

        defmodule Dog do
          require OpenApiSpex
          alias OpenApiSpex.Schema
          OpenApiSpex.schema(%{
            type: :object,
            title: "Dog",
            description: "A representation of a dog. Note that `Dog` will be used as the discriminator value.",
            allOf: [
              PetCommon,
              %Schema {
                type: :object,
                properties: %{
                  packSize: %Schema{
                    type: :integer,
                    format: :int32,
                    description: "the size of the pack the dog is from",
                    default: 0,
                    minimum: 0
                  }
                },
                required: [
                  :packSize
                ]
              }
            ]
          })
        end

        defmodule Pet do
          require OpenApiSpex
          alias OpenApiSpex.Discriminator
          OpenApiSpex.schema(%{
            title: "Pet",
            type: :object,
            discriminator: %Discriminator{
              propertyName: "petType"
            },
            oneOf: [
              Cat,
              Dog
            ]
          })
        end
      end
  """

  alias OpenApiSpex.{
    DeprecatedCast,
    Discriminator,
    ExternalDocumentation,
    OpenApi,
    Reference,
    Schema,
    Xml
  }

  @doc """
  A module implementing the `OpenApiSpex.Schema` behaviour should export a `schema/0` function
  that produces an `OpenApiSpex.Schema` struct.
  """
  @callback schema() :: t

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
    :"x-struct",
    :"x-validate",
    :extensions
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
          email: %Schema{type: :string, format: :email},
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
          title: String.t() | nil,
          multipleOf: number | nil,
          maximum: number | nil,
          exclusiveMaximum: boolean | nil,
          minimum: number | nil,
          exclusiveMinimum: boolean | nil,
          maxLength: integer | nil,
          minLength: integer | nil,
          pattern: String.t() | Regex.t() | nil,
          maxItems: integer | nil,
          minItems: integer | nil,
          uniqueItems: boolean | nil,
          maxProperties: integer | nil,
          minProperties: integer | nil,
          required: [atom] | nil,
          enum: [any] | nil,
          type: data_type | nil,
          allOf: [Schema.t() | Reference.t() | module] | nil,
          oneOf: [Schema.t() | Reference.t() | module] | nil,
          anyOf: [Schema.t() | Reference.t() | module] | nil,
          not: Schema.t() | Reference.t() | module | nil,
          items: Schema.t() | Reference.t() | module | nil,
          properties: %{atom => Schema.t() | Reference.t() | module} | nil,
          additionalProperties: boolean | Schema.t() | Reference.t() | module | nil,
          description: String.t() | nil,
          format: String.t() | atom | nil,
          default: any,
          nullable: boolean | nil,
          discriminator: Discriminator.t() | nil,
          readOnly: boolean | nil,
          writeOnly: boolean | nil,
          xml: Xml.t() | nil,
          externalDocs: ExternalDocumentation.t() | nil,
          example: any,
          deprecated: boolean | nil,
          "x-struct": module | nil,
          "x-validate": module | nil,
          extensions: %{String.t() => any()} | nil
        }

  @typedoc """
  The basic data types supported by openapi.

  [Reference](https://swagger.io/docs/specification/data-models/data-types/)
  """
  @type data_type :: :string | :number | :integer | :boolean | :array | :object

  @typedoc """
  Global schemas lookup by name.
  """
  @type schemas :: %{String.t() => t()}

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

  ## Casting Polymorphic Schemas

  Schemas using `discriminator`, `allOf`, `oneOf`, `anyOf` are cast using the following rules:

    - If a `discriminator` is present, cast the properties defined in the base schema, then
      cast the result using the schema identified by the discriminator. To avoid infinite recursion,
      the discriminator is only dereferenced if the discriminator property has not already been cast.

    - Cast the properties using each schema listing in `allOf`. When a property is defined in
      multiple `allOf` schemas, it will be cast using the first schema listed containing the property.

    - Cast the value using each schema listed in `oneOf`, stopping as soon as a successful cast is made.

    - Cast the value using each schema listed in `anyOf`, stopping as soon as a successful cast is made.
  """
  defdelegate cast(schema, value, schemas), to: DeprecatedCast

  @doc ~S"""
  Validate a value against a Schema.

  This expects that the value has already been `cast` to the appropriate data type.

  ## Examples

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :integer, minimum: 5}, 3, %{})
      {:error, "#: 3 is smaller than minimum 5"}

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :string, pattern: "(.*)@(.*)"}, "joe@gmail.com", %{})
      :ok

      iex> OpenApiSpex.Schema.validate(%OpenApiSpex.Schema{type: :string, pattern: "(.*)@(.*)"}, "joegmail.com", %{})
      {:error, "#: Value \"joegmail.com\" does not match pattern: (.*)@(.*)"}
  """
  @spec validate(Schema.t() | Reference.t(), any, %{String.t() => Schema.t() | Reference.t()}) ::
          :ok | {:error, String.t()}
  defdelegate validate(schema, value, schemas), to: DeprecatedCast
  defdelegate validate(schema, value, path, schemas), to: DeprecatedCast

  @doc """
  Get the names of all properties defined for a schema.

  Includes all properties directly defined in the schema, and all schemas
  included in the `allOf` list.
  """
  def properties(schema = %Schema{type: :object, properties: properties = %{}}) do
    properties
    |> Enum.map(fn {name, property} -> {name, default(property)} end)
    |> Enum.concat(properties(%{schema | properties: nil}))
    |> Enum.uniq_by(fn {name, _property} -> name end)
  end

  def properties(%Schema{allOf: schemas}) when is_list(schemas) do
    Enum.flat_map(schemas, &properties/1) |> Enum.uniq()
  end

  def properties(schema_module) when is_atom(schema_module) do
    properties(schema_module.schema())
  end

  def properties(_), do: []

  @doc """
  Generate example value from a `%Schema{}` struct.

  This is useful as a simple way to generate values for tests.

  Example:

      test "create user", %{conn: conn} do
        user_request_schema = MyAppWeb.Schemas.UserRequest.schema()
        req_body = OpenApiSpex.Schema.example(user_request_schema)

        resp_body =
          conn
          |> post("/users", req_body)
          |> json_response(201)

        assert ...
      end
  """
  @spec example(schema :: Schema.t() | module) :: map | String.t() | number | boolean
  def example(%Schema{example: example} = schema) when not is_nil(example) do
    schema.example
  end

  def example(%Schema{enum: [example | _]}) do
    example
  end

  def example(%Schema{oneOf: [schema | _]}) do
    example(schema)
  end

  def example(%Schema{allOf: schemas}) when is_list(schemas) do
    example_for(schemas, :allOf)
  end

  def example(%Schema{anyOf: schemas}) when is_list(schemas) do
    example_for(schemas, :anyOf)
  end

  def example(%Schema{type: :object} = schema) do
    Map.new(properties(schema), fn {prop_name, _} ->
      property = schema.properties[prop_name]
      example_value = example(property)

      {prop_name, example_value}
    end)
  end

  def example(%Schema{type: :array} = schema) do
    item_example = example(schema.items)
    [item_example]
  end

  def example(%Schema{type: :string, format: :date}), do: "2020-04-20"
  def example(%Schema{type: :string, format: :"date-time"}), do: "2020-04-20T16:20:00Z"
  def example(%Schema{type: :string, format: :uuid}), do: "02ef9c5f-29e6-48fc-9ec3-7ed57ed351f6"

  def example(%Schema{type: :string}), do: ""
  def example(%Schema{type: :integer} = s), do: example_for(s, :integer)
  def example(%Schema{type: :number} = s), do: example_for(s, :number)
  def example(%Schema{type: :boolean}), do: false
  def example(schema_module) when is_atom(schema_module), do: example(schema_module.schema())
  def example(_schema), do: nil

  @doc """
  Generate example value from a `OpenApiSpex.Schema` or a `OpenApiSpex.Reference` struct.

  The second parameter must either be an `OpenApiSpex.OpenApi` struct or a map of schemas.

  See also: `example/1`.
  """
  @spec example(schema :: Schema.t() | module, schemas :: OpenApi.t() | map) ::
          map | String.t() | number | boolean
  def example(schema, %OpenApi{} = spec) do
    example(schema, spec.components.schemas)
  end

  def example(%Schema{type: type} = schema, _schemas)
      when type in [:string, :integer, :number, :boolean] do
    example(schema)
  end

  def example(%Schema{example: example} = schema, _schemas) when not is_nil(example) do
    schema.example
  end

  def example(%Schema{enum: [example | _]}, _schemas), do: example
  def example(%Schema{oneOf: [schema | _]}, schemas), do: example(schema, schemas)
  def example(%Schema{anyOf: [schema | _]}, schemas), do: example(schema, schemas)

  def example(%Schema{allOf: schemas}, all_schemas) when is_list(schemas) do
    example_for(schemas, :allOf, all_schemas)
  end

  def example(%Schema{anyOf: schemas}, all_schemas) when is_list(schemas) do
    example_for(schemas, :anyOf, all_schemas)
  end

  def example(%Schema{type: :object} = schema, schemas) do
    Map.new(properties(schema), fn {prop_name, _} ->
      property = schema.properties[prop_name]

      {prop_name, example(property, schemas)}
    end)
  end

  def example(%Schema{type: :array} = schema, schemas) do
    item_example = example(schema.items, schemas)
    [item_example]
  end

  def example(schema_module, schemas) when is_atom(schema_module) do
    example(schema_module.schema(), schemas)
  end

  def example(%Reference{} = reference, schemas) do
    example(Reference.resolve_schema(reference, schemas), schemas)
  end

  defp example_for(schemas, type) when type in [:anyOf, :allOf] do
    # Only handles :object schemas for now
    schemas
    |> Enum.map(&example/1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp example_for(%{minimum: min} = schema, type)
       when type in [:number, :integer] and not is_nil(min) do
    if schema.exclusiveMinimum do
      min + 1
    else
      min
    end
  end

  defp example_for(%{maximum: max} = schema, type)
       when type in [:number, :integer] and not is_nil(max) do
    if schema.exclusiveMaximum do
      max - 1
    else
      max
    end
  end

  defp example_for(%{format: format}, type)
       when type in [:number, :integer] and format in [:float, :double],
       do: 0.0

  defp example_for(_schema, type) when type in [:number, :integer], do: 0

  defp example_for(schemas, type, all_schemas) when type in [:anyOf, :allOf] do
    schemas
    |> Enum.map(&example(&1, all_schemas))
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp default(schema_module) when is_atom(schema_module), do: schema_module.schema().default
  defp default(%{default: default}), do: default
  defp default(%Reference{}), do: nil

  defp default(value) do
    raise "Expected %Schema{}, schema module, or %Reference{}. Got: #{inspect(value)}"
  end
end
