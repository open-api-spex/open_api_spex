defmodule OpenApiSpex.Plug.RenderSpecTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Plug.{PutApiSpec, RenderSpec}

  defmodule ApiSpec do
    def spec do
      %OpenApi{
        info: %{},
        paths: %{}
      }
    end
  end

  test "call/2" do
    conn =
      Plug.Test.conn(:get, "/openapi")
      |> PutApiSpec.call(ApiSpec)
      |> RenderSpec.call([])

    resp_body = Jason.decode!(conn.resp_body)
    assert %{"openapi" => "3.0.0"} = resp_body
  end
end
