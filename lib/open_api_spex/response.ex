defmodule OpenApiSpex.Response do
  @moduledoc """
  Defines the `OpenApiSpex.Response.t` type.
  """

  alias OpenApiSpex.{Components, Header, Link, MediaType, Reference, Response}

  @enforce_keys :description
  defstruct [
    :description,
    :headers,
    :content,
    :links,
    :extensions
  ]

  @typedoc """
  [Response Object](https://swagger.io/specification/#responseObject)

  Describes a single response from an API Operation, including design-time, static links to operations based on the response.
  """
  @type t :: %__MODULE__{
          description: String.t(),
          headers: %{String.t() => Header.t() | Reference.t()} | nil,
          content: %{String.t() => MediaType.t()} | nil,
          links: %{String.t() => Link.t() | Reference.t()} | nil,
          extensions: %{String.t() => any()} | nil
        }

  @doc """
  Resolve a `Reference` to the `Response` it refers to.

  ## Examples

      iex> alias OpenApiSpex.{Response, Reference}
      ...> responses = %{"aresponse" => %Response{description: "Some response"}}
      ...> Response.resolve_response(%Reference{"$ref": "#/components/responses/aresponse"}, responses)
      %OpenApiSpex.Response{description: "Some response"}
  """
  @spec resolve_response(Reference.t(), Components.responses_map()) :: Response.t() | nil
  def resolve_response(%Response{} = response, _responses), do: response

  def resolve_response(%Reference{"$ref": "#/components/responses/" <> name}, responses),
    do: responses[name]
end
