defmodule OpenApiSpex.Plug.CastAndValidate do
  @moduledoc """
  Module plug that will cast and validate the `Conn.params` and `Conn.body_params` according to the schemas defined for the operation.

  The operation_id can be given at compile time as an argument to `init`:

      plug OpenApiSpex.Plug.CastAndValidate, operation_id: "MyApp.ShowUser"

  For phoenix applications, the operation_id can be obtained at runtime automatically.

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.CastAndValidate
        ...
      end

  If you want customize the error response, you can provide the `:render_error` option to register a plug which creates
  a custom response in the case of a validation error.

  ## Example

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.CastAndValidate, render_error: MyApp.RenderError
        ...
      end

      defmodule MyApp.RenderError do
        def init(opts), do: opts

        def call(conn, reason) do
          msg = Jason.encode!(%{error: reason})

          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.send_resp(400, msg)
        end
      end
  """

  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  def init(opts) do
    opts
    |> Map.new()
    |> Map.put_new(:render_error, OpenApiSpex.Plug.JsonRenderError)
  end

  @impl Plug
  def call(conn = %{private: %{open_api_spex: private_data}}, %{
        operation_id: operation_id,
        render_error: render_error
      }) do
    spec = private_data.spec
    operation = private_data.operation_lookup[operation_id]

    content_type =
      Conn.get_req_header(conn, "content-type")
      |> Enum.at(0, "")
      |> String.split(";")
      |> Enum.at(0)

    private_data = Map.put(private_data, :operation_id, operation_id)
    conn = Conn.put_private(conn, :open_api_spex, private_data)

    with {:ok, conn} <- OpenApiSpex.cast_and_validate(spec, operation, conn, content_type) do
      conn
    else
      {:error, reason} ->
        opts = render_error.init(reason)

        conn
        |> render_error.call(opts)
        |> Plug.Conn.halt()
    end
  end

  def call(
        conn = %{
          private: %{
            phoenix_controller: controller,
            phoenix_action: action,
            open_api_spex: private_data
          }
        },
        opts
      ) do
    operation =
      case private_data.operation_lookup[{controller, action}] do
        nil ->
          operationId = controller.open_api_operation(action).operationId
          operation = private_data.operation_lookup[operationId]

          operation_lookup =
            private_data.operation_lookup
            |> Map.put({controller, action}, operation)

          OpenApiSpex.Plug.Cache.adapter().put(
            private_data.spec_module,
            {private_data.spec, operation_lookup}
          )

          operation

        operation ->
          operation
      end

    if operation.operationId do
      call(conn, Map.put(opts, :operation_id, operation.operationId))
    else
      raise "operationId was not found in action API spec"
    end
  end

  def call(_conn = %{private: %{open_api_spex: _pd}}, _opts) do
    raise ":operation_id was neither provided nor inferred from conn. Consider putting plug OpenApiSpex.Plug.Cast rather into your phoenix controller."
  end

  def call(_conn, _opts) do
    raise ":open_api_spex was not found under :private. Maybe OpenApiSpex.Plug.PutApiSpec was not called before?"
  end
end
