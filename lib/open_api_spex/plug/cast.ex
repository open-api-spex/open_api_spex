defmodule OpenApiSpex.Plug.Cast do
  alias Plug.Conn

  def init(opts), do: opts

  def call(conn = %{private: %{open_api_spex: private_data}}, operation_id: operation_id) do
    spec = private_data.spec
    operation = private_data.operation_lookup[operation_id]
    content_type = Conn.get_req_header(conn, "content-type") |> Enum.at(0)
    private_data = Map.put(private_data, :operation_id, operation_id)
    conn = Conn.put_private(conn, :open_api_spex, private_data)

    case OpenApiSpex.cast_parameters(spec, operation, conn.params, content_type) do
      {:ok, params} -> %{conn | params: params}
      {:error, reason} ->
        conn
        |> Plug.Conn.send_resp(422, "#{reason}")
        |> Plug.Conn.halt()
    end
  end
  def call(conn = %{private: %{phoenix_controller: controller, phoenix_action: action}}, _opts) do
    call(conn, operation_id: controller.open_api_operation(action).operationId)
  end
end