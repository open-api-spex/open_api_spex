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

    get "/users/:id/payment_details", UserController, :payment_details
    post "/users/:id/contact_info", UserController, :contact_info
    post "/users/create_entity", UserController, :create_entity
    get "/openapi", RenderSpec, []

    resources "/pets", PetController, only: [:create, :index, :show, :update]
    post "/pets/:id/adopt", PetController, :adopt
    post "/pets/appointment", PetController, :appointment

    get "/utility/echo/any", UtilityController, :echo_any
    post "/utility/echo/body_params", UtilityController, :echo_body_params

    get "/json_render_error", JsonRenderErrorController, :index

    resources "/jsonapi/carts", JsonApiController, only: [:create, :index, :show]
  end
end
