defmodule OpenApiSpex.Plug.Cast do
  @moduledoc """
  Module plug that will cast the `Conn.params` and `Conn.body_params` according to the schemas defined for the operation.
  Note that when using this plug, the body params are no longer merged into `Conn.params` and must be read from `Conn.body_params`
  separately.

  The operation_id can be given at compile time as an argument to `init`:

      plug OpenApiSpex.Plug.Cast, operation_id: "MyApp.ShowUser"

  For phoenix applications, the operation_id can be obtained at runtime automatically.

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.Cast
        ...
      end

  If you want customize the error response, you can provide the `:render_error` option to register a plug which creates
  a custom response in the case of a validation error.

  ## Example

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.Cast,
        render_error: MyApp.RenderError

        ...
      end

      defmodule MyApp.RenderError do
        def init(opts), do: opts

        def call(conn, reason) do
          msg = %{error: reason} |> Poison.encode!()

          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.send_resp(400, msg)
        end
      end
  """

  @behaviour Plug

  alias OpenApiSpex.Cast.Utils
  alias OpenApiSpex.Plug.PutApiSpec

  @impl Plug
  @deprecated "Use OpenApiSpex.Plug.CastAndValidate instead"
  def init(opts) do
    opts
    |> Map.new()
    |> Map.put_new(:render_error, OpenApiSpex.Plug.DefaultRenderError)
  end

  @impl Plug
  @deprecated "Use OpenApiSpex.Plug.CastAndValidate instead"
  def call(conn = %{private: %{open_api_spex: _private_data}}, %{
        operation_id: operation_id,
        render_error: render_error
      }) do
    {spec, operation_lookup} = PutApiSpec.get_spec_and_operation_lookup(conn)
    operation = operation_lookup[operation_id]

    content_type = Utils.content_type_from_header(conn)

    # credo:disable-for-next-line
    case apply(OpenApiSpex, :cast, [spec, operation, conn, content_type]) do
      {:ok, conn} ->
        conn

      {:error, reason} ->
        opts = render_error.init(reason)

        conn
        |> render_error.call(opts)
        |> Plug.Conn.halt()
    end
  end

  def call(
        conn = %{
          private: %{phoenix_controller: controller, phoenix_action: action, open_api_spex: _pd}
        },
        opts
      ) do
    operation_id = controller.open_api_operation(action).operationId

    if operation_id do
      call(conn, Map.put(opts, :operation_id, operation_id))
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
