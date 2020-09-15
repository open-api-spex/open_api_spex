defmodule OpenApiSpex.Plug.RenderSpec do
  @moduledoc """
  Renders the API spec as a JSON response.

  The API spec must be stored in the conn by `OpenApiSpex.Plug.PutApiSpec` earlier in the plug pipeline.

  ## Example

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        alias MyAppWeb.UserController

        pipeline :api do
          plug :accepts, ["json"]
          plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
        end

        scope "/api" do
          pipe_through :api
          resources "/users", UserController, only: [:create, :index, :show]
          get "/openapi", OpenApiSpex.Plug.RenderSpec, []
        end
      end
  """

  alias OpenApiSpex.Plug.PutApiSpec

  @behaviour Plug

  @json_encoder Enum.find([Jason, Poison], &Code.ensure_loaded?/1)

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    {spec, _} = PutApiSpec.get_spec_and_operation_lookup(conn)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, @json_encoder.encode!(spec))
  end
end
