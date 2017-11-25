defmodule PlugApp.Router.Html do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/swaggerui", to: OpenApiSpex.Plug.SwaggerUI, init_opts: [path: "/api/openapi"]
end

defmodule PlugApp.Router.Api do
  use Plug.Router

  plug OpenApiSpex.Plug.PutApiSpec, module: PlugApp.ApiSpec
  plug :match
  plug :dispatch

  get "/api/users", to: PlugApp.UserHandler.Index
  post "/api/users", to: PlugApp.UserHandler.Create
  get "/api/users/:id", to: PlugApp.UserHandler.Show
  get "/api/openapi", to: OpenApiSpex.Plug.RenderSpec
end

defmodule PlugApp.Router do
  use Plug.Router

  plug Plug.RequestId
  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Poison
  plug :match
  plug :dispatch

  match "/api/*_", to: PlugApp.Router.Api
  match "/*_", to: PlugApp.Router.Html
end

