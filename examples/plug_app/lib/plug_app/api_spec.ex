defmodule PlugApp.ApiSpec do
  alias OpenApiSpex.{Info, OpenApi}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Plug App",
        version: "1.0"
      },
      paths: %{
        "/api/users/{id}" => OpenApiSpex.PathItem.from_routes([
          %{verb: :get, plug: PlugApp.UserHandler.Show, opts: []}
        ]),
        "/api/users" => OpenApiSpex.PathItem.from_routes([
          %{verb: :get, plug: PlugApp.UserHandler.Index, opts: []},
          %{verb: :post, plug: PlugApp.UserHandler.Create, opts: []}
        ])
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end