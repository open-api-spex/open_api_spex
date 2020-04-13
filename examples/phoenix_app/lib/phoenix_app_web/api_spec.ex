defmodule PhoenixAppWeb.ApiSpec do
  alias OpenApiSpex.{Components, Info, OpenApi, OAuthFlow, OAuthFlows, Paths, SecurityScheme}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Phoenix App",
        version: "1.0"
      },
      servers: [OpenApiSpex.Server.from_endpoint(PhoenixAppWeb.Endpoint)],
      paths: Paths.from_router(PhoenixAppWeb.Router),
      components: %Components{
        securitySchemes: %{
          "oauth" => %SecurityScheme{
            type: "oauth2",
            description: "Authenticate with Github OAuth 2",
            flows: %OAuthFlows{
              authorizationCode: %OAuthFlow{
                authorizationUrl: "https://github.com/login/oauth/authorize",
                tokenUrl: "https://github.com/login/oauth/access_token",
                scopes: %{"user:email" => "Read your email address."}
              }
            }
          }
        }
      },
      security: [
        %{
          "oauth" => []
        }
      ]
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
