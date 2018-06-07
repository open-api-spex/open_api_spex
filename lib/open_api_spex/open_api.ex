defmodule OpenApiSpex.OpenApi do
  @moduledoc """
  Defines the `OpenApiSpex.OpenApi.t` type.
  """
  alias OpenApiSpex.{
    Info, Server, Paths, Components,
    SecurityRequirement, Tag, ExternalDocumentation,
    OpenApi
  }
  @enforce_keys [:info, :paths]
  defstruct [
    openapi: "3.0.0",
    info: nil,
    servers: [],
    paths: nil,
    components: nil,
    security: [],
    tags: [],
    externalDocs: nil
  ]

  @typedoc """
  [OpenAPI Object](https://swagger.io/specification/#oasObject)

  This is the root document object of the OpenAPI document.
  """
  @type t :: %OpenApi{
    openapi: String.t,
    info: Info.t,
    servers: [Server.t] | nil,
    paths: Paths.t,
    components: Components.t | nil,
    security: [SecurityRequirement.t] | nil,
    tags: [Tag.t] | nil,
    externalDocs: ExternalDocumentation.t | nil
  }

  defimpl Poison.Encoder do
    def encode(api_spec = %OpenApi{}, options) do
      api_spec
      |> to_json()
      |> Poison.Encoder.encode(options)
    end

    defp to_json(%Regex{source: source}), do: source
    defp to_json(value = %{__struct__: _}) do
      value
      |> Map.from_struct()
      |> to_json()
    end
    defp to_json(value) when is_map(value) do
      value
      |> Stream.map(fn {k,v} -> {to_string(k), to_json(v)} end)
      |> Stream.filter(fn {_, nil} -> false; _ -> true end)
      |> Enum.into(%{})
    end
    defp to_json(value) when is_list(value) do
      Enum.map(value, &to_json/1)
    end
    defp to_json(nil), do: nil
    defp to_json(true), do: true
    defp to_json(false), do: false
    defp to_json(value) when is_atom(value), do: to_string(value)
    defp to_json(value), do: value
  end
end
