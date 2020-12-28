defmodule PhoenixAppWeb.OauthController do
  use PhoenixAppWeb, :controller

  def access_token(conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    query_params = conn.query_params
    IO.inspect(query_params, label: "query_params")
    {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
    body = URI.decode_query(body)
    IO.inspect(body, label: "body")

    config =
      PhoenixAppWeb.Router.swagger_ui_config()
      |> Map.new()
      |> OpenApiSpex.Plug.SwaggerUI.supplement_config(conn)

    oauth = config.oauth

    IO.inspect(config, label: "config")

    provider_params = %{
      client_id: oauth[:client_id],
      client_secret: nil,
      code: body["code"],
      redirect_url: config.oauth2_redirect_url,
      state: nil
    }

    IO.inspect(provider_params, label: "provider_params")

    provider_response = HTTPoison.post!(
      "https://github.com/login/oauth/access_token",
      Jason.encode!(provider_params),
      [{"content-type", "application/json"}])

    provider_body = Jason.decode!(provider_response.body)

    IO.inspect(provider_body, label: "provider_body")

    resp_body =
      %{
        access_token: provider_body["access_token"],
        expires_in: 28800,
        refresh_token: provider_body["refresh_token"],
        refresh_token_expires_in: 15724800,
        scope: "",
        token_type: "bearer"
      }

    json(conn, resp_body)
  end
end
