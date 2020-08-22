defmodule OpenApiSpex.Plug.SwaggerUI do
  @moduledoc """
  Module plug that serves SwaggerUI.

  The full path to the API spec must be given as a plug option.
  The API spec should be served at the given path, see `OpenApiSpex.Plug.RenderSpec`

  SwaggerUI can be configured through a JSON file served with the `Plug.Static` plug.
  See [the swagger-ui docs](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/) for
  details of the configuration options.

  ## Example

      scope "/" do
        pipe_through :browser # Use the default browser stack

        get "/", MyAppWeb.PageController, :index
        get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi", config_url: "/swaggerui_config.json"
      end

      # Other scopes may use custom stacks.
      scope "/api" do
        pipe_through :api
        resources "/users", MyAppWeb.UserController, only: [:index, :create, :show]
        get "/openapi", OpenApiSpex.Plug.RenderSpec, :show
      end
  """
  @behaviour Plug

  @html """
  <!-- HTML for static distribution bundle build -->
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Swagger UI</title>
      <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/3.32.4/swagger-ui.css" >
      <link rel="icon" type="image/png" href="./favicon-32x32.png" sizes="32x32" />
      <link rel="icon" type="image/png" href="./favicon-16x16.png" sizes="16x16" />
      <style>
        html
        {
          box-sizing: border-box;
          overflow: -moz-scrollbars-vertical;
          overflow-y: scroll;
        }
        *,
        *:before,
        *:after
        {
          box-sizing: inherit;
        }
        body {
          margin:0;
          background: #fafafa;
        }
      </style>
    </head>

    <body>
    <div id="swagger-ui"></div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/3.32.4/swagger-ui-bundle.js" charset="UTF-8"> </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/3.32.4/swagger-ui-standalone-preset.js" charset="UTF-8"> </script>
    <script>
    window.onload = function() {
      // Begin Swagger UI call region
      const api_spec_url = new URL(window.location);
      api_spec_url.pathname = "<%= path %>";
      api_spec_url.hash = "";
      const ui = SwaggerUIBundle({
        url: api_spec_url.href,
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "StandaloneLayout",
        requestInterceptor: function(request){
          request.headers["x-csrf-token"] = "<%= csrf_token %>";
          return request;
        },
        displayOperationId: <%= display_operation_id %>,
        configUrl: "<%= config_url %>"
      })
      // End Swagger UI call region
      window.ui = ui
    }
    </script>
    </body>
    </html>
  """

  @doc """
  Initializes the plug.

  ## Options

   * `:path` - *Required* Path to the OpenAPI definition, eg: `"/api/openapi"`
   * `:config_url` - Path to JSON file used for configuring SwaggerUI, eg: `"/swagger_ui_config.json"`

  ## Example

      plug OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi", config_url: "/swagger_ui_config.json"

  """
  @impl Plug
  def init(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    |> Map.put_new(:display_operation_id, false)
    |> Map.put_new(:config_url, "")
  end

  @impl Plug
  def call(conn, %{
        path: path,
        display_operation_id: display_operation_id,
        config_url: config_url
      }) do
    csrf_token = Plug.CSRFProtection.get_csrf_token()
    html = render(path, csrf_token, display_operation_id, config_url)

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end

  require EEx

  EEx.function_from_string(:defp, :render, @html, [
    :path,
    :csrf_token,
    :display_operation_id,
    :config_url
  ])
end
