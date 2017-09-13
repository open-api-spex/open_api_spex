defmodule OpenApiSpexTest.Router do
  use Phoenix.Router

  scope "/api", OpenApiSpexTest do
    resources "/users", UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpecController, :show
  end
end