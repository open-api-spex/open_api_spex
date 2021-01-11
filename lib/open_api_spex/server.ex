defmodule OpenApiSpex.Server do
  @moduledoc """
  Defines the `OpenApiSpex.Server.t` type.
  """
  alias OpenApiSpex.{Server, ServerVariable}

  @enforce_keys :url
  defstruct [
    :url,
    :description,
    variables: %{}
  ]

  @typedoc """
  [Server Object](https://swagger.io/specification/#serverObject)

  An object representing a Server.
  """
  @type t :: %Server{
          url: String.t(),
          description: String.t() | nil,
          variables: %{String.t() => ServerVariable.t()}
        }

  @doc """
  Builds a Server from a phoenix Endpoint module
  """
  @deprecated "Use from_endpoint/1 instead"
  @spec from_endpoint(module, ignored :: any()) :: t
  def from_endpoint(endpoint, _opts) do
    from_endpoint(endpoint)
  end

  @doc """
  Builds a Server from a phoenix Endpoint module
  """
  @spec from_endpoint(module) :: t
  def from_endpoint(endpoint) do
    uri = apply(endpoint, :struct_url, [])
    path = apply(endpoint, :path, [""]) || "/"
    uri = %{uri | path: path}

    %Server{
      url: URI.to_string(uri)
    }
  end
end
