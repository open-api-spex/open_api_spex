defmodule OpenApiSpex.OpenApi do
  alias OpenApiSpex.{
    Info, Server, Paths, Components,
    SecurityRequirement, Tag, ExternalDocumentation,
    OpenApi
  }
  defstruct [
    :info,
    :servers,
    :paths,
    :components,
    :security,
    :tags,
    :externalDocs,
    openapi: "3.0",
  ]
  @type t :: %OpenApi{
    openapi: String.t,
    info: Info.t,
    servers: [Server.t],
    paths: Paths.t,
    components: Components.t,
    security: [SecurityRequirement.t],
    tags: [Tag.t],
    externalDocs: ExternalDocumentation.t
  }

  defimpl Poison.Encoder do
    def encode(api_spec = %OpenApi{}, options) do
      api_spec
      |> to_json()
      |> Poison.Encoder.encode(options)
    end

    defp to_json(value = %{__struct__: _}) do
      value
      |> Map.from_struct()
      |> to_json()
    end
    defp to_json(value) when is_map(value) do
      value
      |> Enum.map(fn {k,v} -> {to_string(k), to_json(v)} end)
      |> Enum.filter(fn {_, nil} -> false; _ -> true end)
      |> Enum.into(%{})
    end
    defp to_json(value) when is_list(value) do
      Enum.map(value, &to_json/1)
    end
    defp to_json(nil) do nil end
    defp to_json(true) do true end
    defp to_json(false) do false end
    defp to_json(value) when is_atom(value) do to_string(value) end
    defp to_json(value) do value end
  end
end