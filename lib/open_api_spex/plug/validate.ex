defmodule OpenApiSpex.Plug.Validate do
  @moduledoc """
  Module plug that validates params against the schema defined for an operation.

  If validation fails, the plug will send a 422 response with the reason as the body.
  This plug should always be run after `OpenApiSpex.Plug.Cast`, as it expects the params map to
  have atom keys and query params converted from strings to the appropriate types.

  ## Example

      defmodule MyApp.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.Cast
        plug OpenApiSpex.Plug.Validate
        ...
      end

  If you want customize the error response, you can provide the `:render_error` option to register a plug which creates
  a custom response in the case of a validation error.

  ## Example

      defmodule MyApp.UserController do
        use Phoenix.Controller
        plug OpenApiSpex.Plug.Cast
        plug OpenApiSpex.Plug.Validate,
        render_error: MyApp.RenderError

        def render_error(conn, reason) do
          msg = %{error: reason} |> Posion.encode!()

          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.send_resp(400, msg)
        end
        ...
      end

      defmodule MyApp.RenderError do
        def init(opts), do: opts

        def call(conn, reason) do
          msg = %{error: reason} |> Posion.encode!()

          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.send_resp(400, msg)
        end
      end
  """
  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  @deprecated "Use OpenApiSpex.Plug.CastAndValidate.init/1 instead"
  def init(opts), do: Keyword.put_new(opts, :render_error, OpenApiSpex.Plug.DefaultRenderError)

  @impl Plug
  @deprecated "Use OpenApiSpex.Plug.CastAndValidate.call/2 instead"
  def call(conn, render_error: render_error) do
    spec = conn.private.open_api_spex.spec
    operation_id = conn.private.open_api_spex.operation_id
    operation_lookup = conn.private.open_api_spex.operation_lookup
    operation = operation_lookup[operation_id]

    content_type =
      Conn.get_req_header(conn, "content-type")
      |> Enum.at(0, "")
      |> String.split(";", parts: 2)
      |> Enum.at(0)

    with :ok <- apply(OpenApiSpex, :validate, [spec, operation, conn, content_type]) do
      conn
    else
      {:error, reason} ->
        opts = render_error.init(reason)

        conn
        |> render_error.call(opts)
        |> Plug.Conn.halt()
    end
  end

  def render_error(conn, reason) do
    conn |> Conn.send_resp(422, "#{reason}")
  end
end
