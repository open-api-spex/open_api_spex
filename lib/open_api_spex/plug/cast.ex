defmodule OpenApiSpex.Plug.Cast do
  def init(opts), do: opts
  def call(conn, operation_id: operation_id) do
    case OpenApiSpex.cast_parameters(conn, operation_id) do
      {:ok, conn} -> conn
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