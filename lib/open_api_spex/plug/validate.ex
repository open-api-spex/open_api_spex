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
  """
  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
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