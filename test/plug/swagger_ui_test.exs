defmodule OpenApiSpec.Plug.SwaggerUITest do
  use ExUnit.Case

  alias OpenApiSpex.Plug.SwaggerUI

  @opts SwaggerUI.init(path: "/ui")

  test "renders csrf token" do
    token = Plug.CSRFProtection.get_csrf_token()

    conn = Plug.Test.conn(:get, "/ui")
    conn = SwaggerUI.call(conn, @opts)
    assert conn.resp_body =~ ~r[pathname.+?/ui]
    assert String.contains?(conn.resp_body, token)
  end

  describe "nonces" do
    test "omits nonces if not configured" do
      conn = Plug.Test.conn(:get, "/ui") |> SwaggerUI.call(@opts)
      refute String.contains?(conn.resp_body, "nonce")
    end

    test "renders with single key" do
      conn =
        Plug.Test.conn(:get, "/ui")
        |> Plug.Conn.assign(:nonce, "my_nonce")
        |> SwaggerUI.call(Map.put(@opts, :csp_nonce_assign_key, :nonce))

      assert String.match?(conn.resp_body, ~r/<style.*nonce="my_nonce"/)
      assert String.match?(conn.resp_body, ~r/<script.*nonce="my_nonce"/)
    end

    test "renders with separate keys" do
      conn =
        Plug.Test.conn(:get, "/ui")
        |> Plug.Conn.assign(:style_src_nonce, "my_style_nonce")
        |> Plug.Conn.assign(:script_src_nonce, "my_script_nonce")
        |> SwaggerUI.call(
          Map.put(@opts, :csp_nonce_assign_key, %{
            script: :script_src_nonce,
            style: :style_src_nonce
          })
        )

      assert String.match?(conn.resp_body, ~r/<style.*nonce="my_style_nonce"/)
      assert String.match?(conn.resp_body, ~r/<script.*nonce="my_script_nonce"/)
    end
  end
end
