defmodule OpenApiSpex.Parameter do
  alias OpenApiSpex.{
    Schema, Reference, Example, MediaType, Parameter
  }
  defstruct [
    :name,
    :in,
    :description,
    :required,
    :deprecated,
    :allowEmptyValue,
    :style,
    :explode,
    :allowReserved,
    :schema,
    :example,
    :examples,
    :content,
  ]
  @type style :: :matrix | :label | :form | :simple | :spaceDelimited | :pipeDelimited | :deep
  @type t :: %__MODULE__{
    name: String.t,
    in: :query | :header | :path | :cookie,
    description: String.t,
    required: boolean,
    deprecated: boolean,
    allowEmptyValue: boolean,
    style: style,
    explode: boolean,
    allowReserved: boolean,
    schema: Schema.t | Reference.t,
    example: any,
    examples: %{String.t => Example.t | Reference.t},
    content: %{String.t => MediaType.t}
  }

  @doc """
  Sets the schema for a parameter from a simple type, reference or Schema
  """
  @spec put_schema(t, Reference.t | Schema.t | atom | String.t) :: t
  def put_schema(parameter = %Parameter{}, type = %Reference{}) do
    %{parameter | schema: type}
  end
  def put_schema(parameter = %Parameter{}, type = %Schema{}) do
    %{parameter | schema: type}
  end
  def put_schema(parameter = %Parameter{}, type) when is_binary(type) or is_atom(type) do
    %{parameter | schema: %Schema{type: type}}
  end
end
