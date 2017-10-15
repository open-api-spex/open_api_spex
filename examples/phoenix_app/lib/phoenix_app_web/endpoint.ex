defmodule PhoenixAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_app

  plug Plug.RequestId
  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Poison
  plug PhoenixAppWeb.Router
end
