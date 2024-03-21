defmodule PhoenixAppWeb.Router do
  use PhoenixAppWeb, :router

  @swagger_ui_config [
    path: "/api/openapi",
    default_model_expand_depth: 3,
    display_operation_id: true,
    oauth2_redirect_url: {:endpoint_url, "/swaggerui/oauth2-redirect.html"},
    oauth: [
      # client_id: "e2195a7487322a0f19bf"
      client_id: "Iv1.d7c611e5607d77b0"
    ],
    csp_nonce_assign_key: %{script: :script_src_nonce, style: :style_src_nonce}
  ]

  @oauth_redirect_config [
    csp_nonce_assign_key: %{script: :script_src_nonce}
  ]

  def swagger_ui_config, do: @swagger_ui_config

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: PhoenixAppWeb.ApiSpec
  end

  scope "/" do
    pipe_through :browser

    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, @swagger_ui_config

    get "/swaggerui/oauth2-redirect.html", OpenApiSpex.Plug.SwaggerUIOAuth2Redirect, @oauth_redirect_config
  end

  scope "/api" do
    pipe_through :api

    resources "/users", PhoenixAppWeb.UserController, only: [:index, :show, :update]
    post "/users/:group_id", PhoenixAppWeb.UserController, :create
    get "/openapi", OpenApiSpex.Plug.RenderSpec, :show
  end

  scope "/" do
    pipe_through :api
    post "/oauth/access_token", PhoenixAppWeb.OauthController, :access_token
  end
end
