defmodule OpenApiSpex.Plug.Cast do
  @moduledoc """
  Module plug that will cast the `Conn.params` according to the schemas defined for the operation.

  The operation_id can be given at compile time as an argument to `init`:

      plug OpenApiSpex.Plug.Cast, operation_id: "MyApp.ShowUser"

  For phoenix applications, the operation_id can be obtained at runtime automatically.

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.Cast
        ...
      end
  """

  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn = %{private: %{open_api_spex: private_data}}, operation_id: operation_id) do
    spec = private_data.spec
    operation = private_data.operation_lookup[operation_id]
    content_type = Conn.get_req_header(conn, "content-type") |> Enum.at(0)
    private_data = Map.put(private_data, :operation_id, operation_id)
    conn = Conn.put_private(conn, :open_api_spex, private_data)

    case OpenApiSpex.cast(spec, operation, conn, content_type) do
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