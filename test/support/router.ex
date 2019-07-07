defmodule OpenApiSpexTest.Router do
  use Phoenix.Router
  alias Plug.Parsers
  alias OpenApiSpex.Plug.{PutApiSpec, RenderSpec}

  pipeline :api do
    plug :accepts, ["json"]
    plug PutApiSpec, module: OpenApiSpexTest.ApiSpec
    plug Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Jason
  end

  scope "/api", OpenApiSpexTest do
    pipe_through :api
    resources "/users", UserController, only: [:create, :index, :show]

    # Used by ParamsTest
    resources "/custom_error_users", CustomErrorUserController, only: [:index]

    # Used by CastAndValidateTest
    scope "/cast_and_validate_test" do
      get "/users", CastAndValidateUserController, :index
      get "/users/:id", CastAndValidateUserController, :show
      post "/users", CastAndValidateUserController, :create
      post "/users/:id/contact_info", CastAndValidateUserController, :contact_info
      post "/users/:id/payment_details", CastAndValidateUserController, :payment_details

      resources "/custom_error_users", CastAndValidate.CustomErrorUserController,
        only: [:index, :create]
    end

    get "/users/:id/payment_details", UserController, :payment_details
    post "/users/:id/contact_info", UserController, :contact_info
    post "/users/create_entity", UserController, :create_entity
    get "/openapi", RenderSpec, []
  end
end
