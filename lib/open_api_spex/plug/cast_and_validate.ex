defmodule OpenApiSpex.Plug.CastAndValidate do
  @moduledoc """
  Module plug that will cast and validate the `Conn.params` and `Conn.body_params` according to the schemas defined for the operation.

  The operation_id can be given at compile time as an argument to `init`:

      plug OpenApiSpex.Plug.CastAndValidate,
        json_render_error_v2: true,
        operation_id: "MyApp.ShowUser"

  For phoenix applications, the operation_id can be obtained at runtime automatically.

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true
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
    opts = Map.new(opts)

    error_renderer =
      if opts[:json_render_error_v2],
        do: OpenApiSpex.Plug.JsonRenderErrorV2,
        else: OpenApiSpex.Plug.JsonRenderError

    Map.put_new(opts, :render_error, error_renderer)
  end

  @impl Plug
  def call(conn = %{private: %{open_api_spex: private_data}}, %{
        operation_id: operation_id,
        render_error: render_error
      }) do
    spec_module = private_data.spec_module
    cache_module = OpenApiSpex.Plug.Cache.adapter()
    {spec, operation_lookup} = cache_module.get(spec_module)
    operation = operation_lookup[operation_id]

    content_type =
      case Conn.get_req_header(conn, "content-type") do
        [header_value | _] ->
          header_value
          |> String.split(";")
          |> Enum.at(0)

        _ ->
          nil
      end

    with {:ok, conn} <- OpenApiSpex.cast_and_validate(spec, operation, conn, content_type) do
      conn
    else
      {:error, errors} ->
        errors = render_error.init(errors)

        conn
        |> render_error.call(errors)
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
    spec_module = private_data.spec_module
    cache_module = OpenApiSpex.Plug.Cache.adapter()
    {spec, operation_lookup} = cache_module.get(spec_module)

    operation =
      case operation_lookup[{controller, action}] do
        nil ->
          operationId = controller.open_api_operation(action).operationId
          operation = operation_lookup[operationId]
          operation_lookup = Map.put(operation_lookup, {controller, action}, operation)
          cache_module.put(spec_module, {spec, operation_lookup})
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
