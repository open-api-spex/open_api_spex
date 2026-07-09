defmodule OpenApiSpex.Plug.SwaggerUITest do
  use ExUnit.Case

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :open_api_spex_test
  end

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

  describe "phoenix endpoint path expansion" do
    setup do
      # Just to avoid warnings
      Application.put_env(:open_api_spex_test, Endpoint, [])

      start_supervised!(
        {Endpoint, url: [scheme: "https", host: "example.com", port: 1234, path: "/my_app"]}
      )

      :ok
    end

    test "expands path with endpoint path prefix" do
      conn = conn_with_endpoint() |> SwaggerUI.call(@opts)
      assert conn.resp_body =~ ~r[pathname.+?/my_app/ui]
    end

    test "expands paths with endpoint path prefix" do
      opts = SwaggerUI.init(paths: [latest: "/api/openapi", legacy: "/legacy/openapi"])
      conn = conn_with_endpoint() |> SwaggerUI.call(opts)
      assert conn.resp_body =~ "/my_app/api/openapi"
      assert conn.resp_body =~ "/my_app/legacy/openapi"
    end

    test "does not expand absolute URLs in paths" do
      opts =
        SwaggerUI.init(paths: [local: "/api/openapi", remote: "http://other.host/api/openapi"])

      conn = conn_with_endpoint() |> SwaggerUI.call(opts)
      assert conn.resp_body =~ "/my_app/api/openapi"
      assert conn.resp_body =~ "http://other.host/api/openapi"
    end

    test "expands oauth2_redirect_url with endpoint_url tuple" do
      opts =
        SwaggerUI.init(
          path: "/ui",
          oauth2_redirect_url: {:endpoint_url, "/oauth2-redirect.html"}
        )

      conn = conn_with_endpoint() |> SwaggerUI.call(opts)
      assert conn.resp_body =~ "https://example.com:1234/my_app/oauth2-redirect.html"
    end

    test "does not expand path without phoenix endpoint" do
      conn = Plug.Test.conn(:get, "/ui") |> SwaggerUI.call(@opts)
      assert conn.resp_body =~ ~r[pathname.+?/ui]
      refute conn.resp_body =~ "/my_app"
    end
  end

  defp conn_with_endpoint(path \\ "/ui") do
    Plug.Test.conn(:get, path)
    |> Plug.Conn.put_private(:phoenix_endpoint, Endpoint)
  end
end
