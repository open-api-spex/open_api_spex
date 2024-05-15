defmodule OpenApiSpex.Plug.CastAndValidate do
  @moduledoc """
  Module plug that will cast and validate the `Conn.params` and `Conn.body_params` according to the schemas defined for the operation.
  Note that when using this plug, the body params are no longer merged into `Conn.params` and must be read from `Conn.body_params`
  separately.

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

  Casted params and body params are always stored in `conn.private`.
  The option `:replace_params` can be set to false to avoid overwriting conn `:body_params` and `:params`
  with their casted version.

      plug OpenApiSpex.Plug.CastAndValidate,
        json_render_error_v2: true,
        operation_id: "MyApp.ShowUser",
        replace_params: false

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

  alias OpenApiSpex.Plug.PutApiSpec
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
  def call(
        conn = %{private: %{open_api_spex: _}},
        %{
          operation_id: operation_id,
          render_error: render_error
        } = opts
      ) do
    {spec, operation_lookup} = PutApiSpec.get_spec_and_operation_lookup(conn)
    operation = operation_lookup[operation_id]
    conn = put_operation_id(conn, operation)

    cast_opts = opts |> Map.take([:replace_params]) |> Map.to_list()

    case OpenApiSpex.cast_and_validate(spec, operation, conn, nil, cast_opts) do
      {:ok, conn} ->
        conn

      {:error, errors} ->
        errors = render_error.init(errors)

        conn
        |> render_error.call(errors)
        |> Conn.halt()
    end
  end

  def call(
        conn = %{
          private: %{
            phoenix_controller: controller,
            phoenix_action: action,
            open_api_spex: _
          }
        },
        opts
      ) do
    {_spec, operation_lookup} = PutApiSpec.get_spec_and_operation_lookup(conn)

    # This caching is to improve performance of extracting Operation specs
    # at runtime when they're using the @doc-based syntax.
    operation_lookup =
      case operation_lookup[{controller, action}] do
        nil ->
          operation = controller.open_api_operation(action)

          if operation do
            operation =
              PutApiSpec.get_and_cache_controller_action(
                conn,
                operation.operationId,
                {controller, action}
              )

            {:found_it, operation}
          else
            # this is the case when operation: false was used
            {:skip_it, nil}
          end

        operation ->
          {:found_it, operation}
      end

    case operation_lookup do
      {:skip_it, _} ->
        conn

      {:found_it, nil} ->
        raise "operationId was not found in action API spec"

      {:found_it, operation} ->
        call(conn, opts |> Map.put(:operation_id, operation.operationId))
    end
  end

  def call(_conn = %{private: %{open_api_spex: _pd}}, _opts) do
    raise ":operation_id was neither provided nor inferred from conn. Consider putting plug OpenApiSpex.Plug.CastAndValidate rather into your phoenix controller."
  end

  def call(_conn, _opts) do
    raise ":open_api_spex was not found under :private. Maybe PutApiSpec was not called before?"
  end

  defp put_operation_id(conn, operation) do
    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:operation_id, operation.operationId)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end
end
