defmodule OpenApiSpex.ServerTest do
  use ExUnit.Case
  alias OpenApiSpex.{Server}
  alias OpenApiSpexTest.Endpoint

  describe "Server" do
    test "from_endpoint" do
      Application.put_env(:open_api_spex_test, Endpoint, [
        url: [
          scheme: "https",
          host: "example.com",
          port: 1234,
          path: "/api/v1/"
        ]
      ])
      Endpoint.start_link()

      server = Server.from_endpoint(Endpoint)

      assert %{
        url: "https://example.com:1234/api/v1/"
      } = server
    end
  end

end

