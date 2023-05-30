defmodule PhoenixAppWeb.ApiSpec do
  alias OpenApiSpex.{
    Components,
    Info,
    OpenApi,
    OAuthFlow,
    OAuthFlows,
    Paths,
    SecurityScheme,
    Schema,
    MediaType,
    Response
  }

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
                tokenUrl: "/oauth/access_token",
                scopes: %{"user:email" => "Read your email address."}
              }
            }
          }
        },
        responses: %{
          unprocessable_entity: %Response{
            description: "Unprocessable Entity",
            content: %{"application/json" => %MediaType{schema: %Schema{type: :object}}}
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
