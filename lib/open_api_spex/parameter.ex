defmodule OpenApiSpex.Parameter do
  @moduledoc """
  Defines the `OpenApiSpex.Parameter.t` type.
  """
  alias OpenApiSpex.{
    Schema,
    Reference,
    Example,
    MediaType,
    Parameter
  }

  @enforce_keys [:name, :in]
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
    :content
  ]

  @typedoc """
  Valid values for the `in` key in the `OpenApiSpex.Parameter` struct.
  """
  @type location :: :path | :query | :header | :cookie

  @typedoc """
  Valid values for the `style` key in the `OpenApiSpex.Parameter` struct.
  """
  @type style ::
          :matrix | :label | :form | :simple | :spaceDelimited | :pipeDelimited | :deepObject

  @typedoc """
  [Parameter Object](https://swagger.io/specification/#parameterObject)

  Describes a single operation parameter.

  A unique parameter is defined by a combination of a name and location.

  ## Parameter Locations

  There are four possible parameter locations specified by the in field:

    - path: Used together with Path Templating, where the parameter value is actually part of the operation's URL. This does not include the host or base path of the API. For example, in `/items/{itemId}`, the path parameter is itemId.
    - query: Parameters that are appended to the URL. For example, in `/items?id=###`, the query parameter is id.
    - header: Custom headers that are expected as part of the request. Note that RFC7230 states header names are case insensitive.
    - cookie: Used to pass a specific cookie value to the API.
  """
  @type t :: %__MODULE__{
          name: atom,
          in: location,
          description: String.t() | nil,
          required: boolean | nil,
          deprecated: boolean | nil,
          allowEmptyValue: boolean | nil,
          style: style | nil,
          explode: boolean | nil,
          allowReserved: boolean | nil,
          schema: Schema.t() | Reference.t() | atom | nil,
          example: any,
          examples: %{String.t() => Example.t() | Reference.t()} | nil,
          content: %{String.t() => MediaType.t()} | nil
        }

  @type parameters :: %{String.t() => t | Reference.t()} | nil

  @doc """
  Sets the schema for a parameter from a simple type, reference or Schema
  """
  @spec put_schema(t, Reference.t() | Schema.t() | atom) :: t
  def put_schema(parameter = %Parameter{}, type = %Reference{}) do
    %{parameter | schema: type}
  end

  def put_schema(parameter = %Parameter{}, type = %Schema{}) do
    %{parameter | schema: type}
  end

  def put_schema(parameter = %Parameter{}, type)
      when type in [:boolean, :integer, :number, :string, :array, :object] do
    %{parameter | schema: %Schema{type: type}}
  end

  def put_schema(parameter = %Parameter{}, type) when is_atom(type) do
    %{parameter | schema: type}
  end

  @doc """
  Gets the schema for a parameter, from the `schema` key or `content` key, which ever is populated.
  """
  @spec schema(Parameter.t()) :: Schema.t() | Reference.t() | atom
  def schema(%Parameter{schema: schema = %{}}) do
    schema
  end

  def schema(%Parameter{content: content = %{}}) do
    {_type, %MediaType{schema: schema}} = Enum.at(content, 0)
    schema
  end
end
