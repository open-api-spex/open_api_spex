defmodule OpenApiSpec.Plug.SwaggerUITest do
  use ExUnit.Case

  alias OpenApiSpex.Plug.SwaggerUI

  setup_all do
    start_supervised!(OpenApiSpexTest.Endpoint)
    :ok
  end

  test "renders csrf token" do
    config = SwaggerUI.init(path: "/ui")

    token = Plug.CSRFProtection.get_csrf_token()

    conn =
      Plug.Test.conn(:get, "/ui")
      |> Plug.Conn.put_private(:phoenix_endpoint, OpenApiSpexTest.Endpoint)

    conn = SwaggerUI.call(conn, config)
    assert conn.resp_body =~ ~r[pathname.+?"/ui"]
    assert String.contains?(conn.resp_body, token)
  end

  Application.put_env(:open_api_spex_test, OpenApiSpexTest.Endpoint,
    url: [scheme: "https", host: "some-host.com", port: 1234, path: "/some-prefix"]
  )

  test "generate actual path dependent to endpoint" do
    config = SwaggerUI.init(path: {:endpoint_path, "/ui"})

    conn =
      Plug.Test.conn(:get, "/ui")
      |> Plug.Conn.put_private(:phoenix_endpoint, OpenApiSpexTest.Endpoint)

    conn = SwaggerUI.call(conn, config)
    assert conn.resp_body =~ ~r[pathname.+?"/some-prefix/ui"]
  end

  test "generate actual url dependent to endpoint" do
    config = SwaggerUI.init(path: {:endpoint_url, "/ui"})

    conn =
      Plug.Test.conn(:get, "/ui")
      |> Plug.Conn.put_private(:phoenix_endpoint, OpenApiSpexTest.Endpoint)

    conn = SwaggerUI.call(conn, config)
    assert conn.resp_body =~ ~r[pathname.+?"https://some-host.com:1234/some-prefix/ui"]
  end
end
