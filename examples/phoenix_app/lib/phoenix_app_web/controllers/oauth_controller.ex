defmodule PhoenixAppWeb.OauthController do
  use PhoenixAppWeb, :controller

  def access_token(conn = %Plug.Conn{}, _params) do
    provider_params = conn.body_params

    provider_response =
      HTTPoison.post!(
        "https://github.com/login/oauth/access_token",
        Jason.encode!(provider_params),
        [{"content-type", "application/json"}]
      )

    provider_body = provider_response.body

    provider_body =
      case provider_body do
        "{" <> _ -> Jason.decode!(provider_body)
        _ -> URI.decode_query(provider_body)
      end

    json(conn, provider_body)
  end
end
