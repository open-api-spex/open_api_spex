defmodule OpenApiSpex.Plug.JsonRenderError do
  @behaviour Plug

  alias Plug.Conn
  alias OpenApiSpex.OpenApi

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, reasons) when is_list(reasons) do
    response = %{
      errors: Enum.map(reasons, &to_string/1)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end

  def call(conn, reason) do
    call(conn, [reason])
  end
end
