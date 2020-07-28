defmodule OpenApiSpex.PhoenixControllerTest do
  use ExUnit.Case, async: true

  use Phoenix.ConnTest
  import OpenApiSpexTest.Router.Helpers

  # The default endpoint for testing
  @endpoint OpenApiSpexTest.Endpoint

  test "foo" do
    resp_body =
      conn_with_headers()
      |> post("/api/pets/nope/adopt")
      |> json_response(200)

    assert resp_body == :foo
  end

  defp conn_with_headers do
    build_conn()
    |> Plug.Conn.put_req_header("accept", "application/json")
    |> Plug.Conn.put_req_header("content-type", "application/json")
  end
end
