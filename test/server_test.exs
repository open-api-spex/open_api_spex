defmodule OpenApiSpex.ServerTest do
  use ExUnit.Case
  alias OpenApiSpex.{Server}
  alias OpenApiSpexText.Endpoint

  describe "Server" do
    test "from_endpoint" do
      Application.put_env(:phoenix_swagger, Endpoint, [
        url: [host: "example.com", port: 1234, path: "/api/v1/", scheme: :https],
      ])

      server = Server.from_endpoint(Endpoint, otp_app: :phoenix_swagger)

      assert %{
        url: "https://example.com:1234/api/v1/"
      } = server
    end
  end

end