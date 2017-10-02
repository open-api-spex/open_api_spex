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
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, Poison.encode!(conn.private.open_api_spex.spec))
  end
end