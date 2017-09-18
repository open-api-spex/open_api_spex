defmodule OpenApiSpexTest.Router do
  use Phoenix.Router

  pipeline :api do
    plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
    plug OpenApiSpex.Plug.PutApiSpec, module: OpenApiSpexTest.ApiSpec
  end

  scope "/api", OpenApiSpexTest do
    pipe_through :api
    resources "/users", UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpecController, :show
  end
end