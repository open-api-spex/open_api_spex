defmodule OpenApiSpexTest.Router do
  use Phoenix.Router
  alias Plug.Parsers
  alias OpenApiSpexTest.UserController
  alias OpenApiSpex.Plug.{PutApiSpec, RenderSpec}

  pipeline :api do
    plug :accepts, ["json"]
    plug PutApiSpec, module: OpenApiSpexTest.ApiSpec
    plug Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  end

  scope "/api" do
    pipe_through :api
    resources "/users", UserController, only: [:create, :index, :show]
    get "/users/:id/payment_details", UserController, :payment_details
    get "/openapi", RenderSpec, []
  end
end
