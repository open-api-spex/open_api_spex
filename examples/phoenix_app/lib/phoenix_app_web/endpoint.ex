defmodule PhoenixAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_app

  plug Plug.RequestId
  plug Plug.Logger
  plug Plug.Static, at: "/", from: {:phoenix_app, "priv/static"}
  plug Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason
  plug PhoenixAppWeb.Router
end
