defmodule PhoenixAppWeb.ApiSpec do
  alias OpenApiSpex.{Info, OpenApi, Paths}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Phoenix App",
        version: "1.0"
      },
      servers: [OpenApiSpex.Server.from_endpoint(PhoenixAppWeb.Endpoint)],
      paths: Paths.from_router(PhoenixAppWeb.Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
