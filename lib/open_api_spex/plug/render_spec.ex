defmodule OpenApiSpex.Plug.RenderSpec do
  @moduledoc """
  Renders the API spec stored earlier in the Conn by `OpenApiSpex.Plug.PutApiSpec`
  """
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, Poison.encode!(conn.private.open_api_spex.spec))
  end
end