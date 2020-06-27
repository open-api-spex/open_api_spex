defmodule OpenApiSpex.Plug.JsonRenderErrorTest do
  use ExUnit.Case, async: true

  test "render error" do
    conn =
      :get
      |> Plug.Test.conn("/api/json_render_error?validParam=invalid")
      |> OpenApiSpexTest.Router.call([])

    assert conn.status == 422
    resp_body = Jason.decode!(conn.resp_body)

    assert resp_body == %{
             "errors" => [
               %{
                 "detail" => "Invalid boolean. Got: string",
                 "message" => "Invalid boolean. Got: string",
                 "source" => %{"pointer" => "/validParam"},
                 "title" => "Invalid value"
               }
             ]
           }
  end
end
