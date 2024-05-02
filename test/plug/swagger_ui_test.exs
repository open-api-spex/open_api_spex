defmodule OpenApiSpec.Plug.SwaggerUITest do
  use ExUnit.Case

  alias OpenApiSpex.Plug.SwaggerUI
  alias OpenApiSpexTest.Endpoint

  test "renders csrf token" do
    start_supervised!(Endpoint)

    config = SwaggerUI.init(path: "/ui")

    token = Plug.CSRFProtection.get_csrf_token()

    conn =
      Plug.Test.conn(:get, "/ui")
      |> Plug.Conn.put_private(:phoenix_endpoint, Endpoint)

    conn = SwaggerUI.call(conn, config)
    assert conn.resp_body =~ ~r[pathname.+?"/ui"]
    assert String.contains?(conn.resp_body, token)
  end

  test "generate actual path dependent to endpoint" do
    Application.put_env(:open_api_spex_test, Endpoint, url: [path: "/some-prefix"])

    start_supervised!(Endpoint)

    config = SwaggerUI.init(path: {:endpoint_path, "/ui"})

    conn =
      Plug.Test.conn(:get, "/ui")
      |> Plug.Conn.put_private(:phoenix_endpoint, Endpoint)

    conn = SwaggerUI.call(conn, config)
    assert conn.resp_body =~ ~r[pathname.+?"/some-prefix/ui"]
  end

  test "generate actual url dependent to endpoint" do
    Application.put_env(:open_api_spex_test, Endpoint,
      url: [scheme: "https", host: "some-host.com", port: 1234, path: "/some-prefix"]
    )

    start_supervised!(Endpoint)

    config = SwaggerUI.init(path: {:endpoint_url, "/ui"})

    conn =
      Plug.Test.conn(:get, "/ui")
      |> Plug.Conn.put_private(:phoenix_endpoint, Endpoint)

    conn = SwaggerUI.call(conn, config)
    assert conn.resp_body =~ ~r[pathname.+?"https://some-host.com:1234/some-prefix/ui"]
  end
end
