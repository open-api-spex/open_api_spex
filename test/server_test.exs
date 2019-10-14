defmodule OpenApiSpex.ServerTest do
  use ExUnit.Case
  alias OpenApiSpex.{Server}
  alias OpenApiSpexTest.Endpoint

  @otp_app :open_api_spex_test

  describe "Server" do
    test "from_endpoint/1" do
      setup_endpoint()

      server = Server.from_endpoint(Endpoint)

      assert %{
               url: "https://example.com:1234/api/v1/"
             } = server
    end
  end

  defp setup_endpoint do
    Application.put_env(@otp_app, Endpoint,
      url: [
        scheme: "https",
        host: "example.com",
        port: 1234,
        path: "/api/v1/"
      ]
    )

    Endpoint.start_link()
  end
end
