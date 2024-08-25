defmodule OpenApiSpex.Plug.SwaggerUI do
  @moduledoc """
  Module plug that serves SwaggerUI.

  The full path to the API spec must be given as a plug option.
  The API spec should be served at the given path, see `OpenApiSpex.Plug.RenderSpec`

  ## Configuring SwaggerUI

  SwaggerUI can be configured through plug `opts`.
  All options will be converted from `snake_case` to `camelCase` and forwarded to the `SwaggerUIBundle` constructor.
  See the [swagger-ui configuration docs](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/) for details.
  Should dynamic configuration be required, the `config_url` option can be set to an API endpoint that will provide additional config.

  ## Example

      scope "/" do
        pipe_through :browser # Use the default browser stack

        get "/", MyAppWeb.PageController, :index
        get "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
          path: "/api/openapi",
          default_model_expand_depth: 3,
          display_operation_id: true
      end

      # Other scopes may use custom stacks.
      scope "/api" do
        pipe_through :api
        resources "/users", MyAppWeb.UserController, only: [:index, :create, :show]
        get "/openapi", OpenApiSpex.Plug.RenderSpec, :show
      end

      # Use a different Swagger UI version
      scope "/" do
        pipe_through :browser

        get "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
          path: "/api/openapi",
          swagger_ui_js_bundle_url: "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.14.0/swagger-ui-bundle.js",
          swagger_ui_js_standalone_preset_url: "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.14.0/swagger-ui-standalone-preset.js",
          swagger_ui_css_url: "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.14.0/swagger-ui.css"
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
      <link rel="stylesheet" type="text/css" href="<%= config[:swagger_ui_css_url] || "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.17.14/swagger-ui.css" %>" >
      <link rel="icon" type="image/png" href="./favicon-32x32.png" sizes="32x32" />
      <link rel="icon" type="image/png" href="./favicon-16x16.png" sizes="16x16" />
      <%= if style_src_nonce do %>
        <style nonce="<%= style_src_nonce %>">
      <% else %>
        <style>
      <% end %>
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

    <script src="<%= config[:swagger_ui_js_bundle_url] || "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.17.14/swagger-ui-bundle.js" %>" charset="UTF-8"> </script>
    <script src="<%= config[:swagger_ui_js_standalone_preset_url] || "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.17.14/swagger-ui-standalone-preset.js" %>" charset="UTF-8"> </script>
    <%= if script_src_nonce do %>
      <script nonce="<%= script_src_nonce %>">
    <% else %>
      <script>
    <% end %>
    window.onload = function() {
      // Begin Swagger UI call region
      const api_spec_url = new URL(window.location);
      api_spec_url.pathname = "<%= config.path %>";
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
          server_base = window.location.protocol + "//" + window.location.host;
          if(request.url.startsWith(server_base)) {
            request.headers["x-csrf-token"] = "<%= csrf_token %>";
          } else {
            delete request.headers["x-csrf-token"];
          }
          return request;
        }
        <%= for {k, v} <- Map.drop(config, [:path, :oauth, :csp_nonce_assign_key]) do %>
        , <%= camelize(k) %>: <%= encode_config(camelize(k), v) %>
        <% end %>
      })
      // End Swagger UI call region
      <%= if config[:oauth] do %>
        ui.initOAuth(
          <%= config.oauth
              |> Map.new(fn {k, v} -> {camelize(k), v} end)
              |> OpenApiSpex.OpenApi.json_encoder().encode!()
          %>
        )
      <% end %>
      window.ui = ui
    }
    </script>
    </body>
    </html>
  """

  @ui_config_methods [
    "operationsSorter",
    "tagsSorter",
    "onComplete",
    "requestInterceptor",
    "responseInterceptor",
    "modelPropertyMacro",
    "parameterMacro",
    "initOAuth",
    "preauthorizeBasic",
    "preauthorizeApiKey"
  ]

  @doc """
  Initializes the plug.

  ## Options

   * `:path` - Required. The URL path to the API definition.
   * `:oauth` - Optional. Config to pass to the `SwaggerUIBundle.initOAuth()` function.
   * `:csp_nonce_assign_key` - Optional. An assign key to find the CSP nonce value used
     for assets. Supports either `atom()` or a map of type
     `%{optional(:script) => atom(), optional(:style) => atom()}`. You will probably
     want to set this on the `SwaggerUIOAuth2Redirect` plug as well.
   * `:swagger_ui_js_bundle_url` - Optional. An URL to SwaggerUI JavaScript bundle.
   * `:swagger_ui_js_standalone_preset_url` - Optional. An URL to SwaggerUI JavaScript Standalone Preset.
   * `:swagger_ui_css_url` - Optional. An URL to SwaggerUI CSS bundle.
   * all other opts - forwarded to the `SwaggerUIBundle` constructor

  ## Example

      get "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
        path: "/api/openapi",
        default_model_expand_depth: 3,
        display_operation_id: true,
        csp_nonce_assign_key: %{script: :script_src_nonce, style: :style_src_nonce}
  """
  @impl Plug
  def init(opts) when is_list(opts) do
    Map.new(opts)
  end

  @impl Plug
  def call(conn, config) do
    csrf_token = Plug.CSRFProtection.get_csrf_token()
    config = supplement_config(config, conn)

    html =
      render(
        config,
        csrf_token,
        get_nonce(conn, config, :style),
        get_nonce(conn, config, :script)
      )

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end

  require EEx

  EEx.function_from_string(:defp, :render, @html, [
    :config,
    :csrf_token,
    :style_src_nonce,
    :script_src_nonce
  ])

  defp camelize(identifier) do
    identifier
    |> to_string
    |> String.split("_", parts: 2)
    |> case do
      [first] -> first
      [first, rest] -> first <> Macro.camelize(rest)
    end
  end

  defp encode_config("tagsSorter", "alpha" = value) do
    OpenApiSpex.OpenApi.json_encoder().encode!(value)
  end

  defp encode_config("operationsSorter", value) when value == "alpha" or value == "method" do
    OpenApiSpex.OpenApi.json_encoder().encode!(value)
  end

  defp encode_config(key, value) do
    case Enum.member?(@ui_config_methods, key) do
      true -> value
      false -> OpenApiSpex.OpenApi.json_encoder().encode!(value)
    end
  end

  if Code.ensure_loaded?(Phoenix.Controller) do
    defp supplement_config(%{oauth2_redirect_url: {:endpoint_url, path}} = config, conn) do
      endpoint_module = Phoenix.Controller.endpoint_module(conn)
      url = Path.join(endpoint_module.url(), path)
      Map.put(config, :oauth2_redirect_url, url)
    end
  end

  defp supplement_config(config, _conn) do
    config
  end

  def get_nonce(conn, config, type) do
    case config[:csp_nonce_assign_key] do
      key when is_atom(key) -> conn.assigns[key]
      %{^type => key} when is_atom(key) -> conn.assigns[key]
      _ -> nil
    end
  end
end
