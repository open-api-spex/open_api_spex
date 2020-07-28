defmodule OpenApiSpexTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :open_api_spex_test

  plug OpenApiSpexTest.Router
end
