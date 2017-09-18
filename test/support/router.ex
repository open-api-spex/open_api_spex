defmodule OpenApiSpexTest.Router do
  use Phoenix.Router

  pipeline :api do
    plug OpenApiSpex.Plug.PutApiSpec, module: OpenApiSpexTest.ApiSpec
    plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  end

  scope "/api" do
    pipe_through :api
    resources "/users", OpenApiSpexTest.UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
end