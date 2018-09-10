defmodule OpenApiSpexTest.Router do
  use Phoenix.Router
  alias Plug.Parsers
  alias OpenApiSpexTest.UserController
  alias OpenApiSpexTest.CustomErrorUserController
  alias OpenApiSpex.Plug.{PutApiSpec, RenderSpec}

  pipeline :api do
    plug :accepts, ["json"]
    plug PutApiSpec, module: OpenApiSpexTest.ApiSpec
    plug Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  end

  scope "/api" do
    pipe_through :api
    resources "/users", UserController, only: [:create, :index, :show]
    resources "/custom_error_users", CustomErrorUserController, only: [:index]
    get "/users/:id/payment_details", UserController, :payment_details
    post "/users/:id/contact_info", UserController, :contact_info
    post "/users/create_entity", UserController, :create_entity
    get "/openapi", RenderSpec, []
  end
end
