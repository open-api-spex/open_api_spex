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
            description: "Properties common to all Pets"
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
                    enum: ["clueless", "lazy", "adventurous", "aggresive"]
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
          alias OpenApiSpex.{Schema, Discriminator}
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
  """

  alias OpenApiSpex.{
    Schema,
    Reference,
    Discriminator,
    Xml,
    ExternalDocumentation
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
          "x-struct": module | nil
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
  Get the names of all properties definied for a schema.

  Includes all properties directly defined in the schema, and all schemas
  included in the `allOf` list.
  """
  def properties(schema = %Schema{type: :object, properties: properties = %{}}) do
    for({name, property} <- properties, do: {name, default(property)}) ++
      properties(%{schema | properties: nil})
  end

  def properties(%Schema{allOf: schemas}) when is_list(schemas) do
    Enum.flat_map(schemas, &properties/1) |> Enum.uniq()
  end

  def properties(schema_module) when is_atom(schema_module) do
    properties(schema_module.schema())
  end

  def properties(_), do: []

  defp default(schema_module) when is_atom(schema_module), do: schema_module.schema().default
  defp default(%{default: default}), do: default
end
