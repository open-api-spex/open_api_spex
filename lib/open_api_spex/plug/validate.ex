defmodule OpenApiSpex.Plug.Validate do
  alias Plug.Conn

  def init(opts), do: opts
  def call(conn, _opts) do
    spec = conn.private.open_api_spex.spec
    operation_id = conn.private.open_api_spex.operation_id
    operation_lookup = conn.private.open_api_spex.operation_lookup
    operation = operation_lookup[operation_id]
    content_type = Conn.get_req_header(conn, "content-type") |> Enum.at(0)

    with :ok <- OpenApiSpex.validate(spec, operation, conn.params, content_type) do
      conn
    else
      {:error, reason} ->
        conn
        |> Conn.send_resp(422, "#{reason}")
        |> Conn.halt()
    end
  end
end