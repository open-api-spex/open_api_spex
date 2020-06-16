defmodule OpenApiSpexTest.Router2 do
  use Phoenix.Router
  alias Plug.Parsers
  alias OpenApiSpex.Plug.PutApiSpec

  pipeline :api do
    plug :accepts, ["json"]
    plug PutApiSpec, module: OpenApiSpexTest.ApiSpec
    plug Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Jason
  end

  scope "/api", OpenApiSpexTest do
    pipe_through :api
    get "/jsonapi/carts", JsonApiController, :index
    # get "/jsonapi/carts/:id", JsonApiController, :show
  end
end
