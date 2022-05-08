defmodule OpenApiSpexTest.Router do
  use Phoenix.Router
  alias Plug.Parsers
  alias OpenApiSpex.Plug.PutApiSpec

  pipeline :api do
    plug :accepts, ["json"]
    plug PutApiSpec, module: OpenApiSpexTest.ApiSpec
    plug Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Jason
  end

  scope "/api" do
    pipe_through :api
    resources "/users", OpenApiSpexTest.UserController, only: [:create, :index, :show]
    get "/noapi", OpenApiSpexTest.NoApiController, :noapi

    # Used by ParamsTest
    resources "/custom_error_users", OpenApiSpexTest.CustomErrorUserController, only: [:index]

    get "/users/:id/payment_details", OpenApiSpexTest.UserController, :payment_details
    post "/users/:id/contact_info", OpenApiSpexTest.UserController, :contact_info
    post "/users/create_entity", OpenApiSpexTest.UserController, :create_entity
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []

    resources "/pets", OpenApiSpexTest.PetController, only: [:create, :index, :show, :update]
    post "/pets/:id/adopt", OpenApiSpexTest.PetController, :adopt
    post "/pets/appointment", OpenApiSpexTest.PetController, :appointment

    get "/utility/echo/any", OpenApiSpexTest.UtilityController, :echo_any
    post "/utility/echo/body_params", OpenApiSpexTest.UtilityController, :echo_body_params

    get "/json_render_error", OpenApiSpexTest.JsonRenderErrorController, :index
  end
end
