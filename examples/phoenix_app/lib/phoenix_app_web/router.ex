defmodule PhoenixAppWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: PhoenixAppWeb.ApiSpec
  end

  scope "/" do
    pipe_through :browser
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  scope "/api" do
    pipe_through :api
    resources "/users", PhoenixAppWeb.UserController, only: [:index, :create, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, :show
  end
end
