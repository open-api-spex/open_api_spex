defmodule OpenApiSpex.Plug.SwaggerUIOAuth2Redirect do
  @moduledoc """
  This plug will handle the callback from an OAuth server
  """
  @behaviour Plug

  import Plug.Conn

  alias OpenApiSpex.Plug.SwaggerUI

  @html """
    <!-- HTML for static distribution bundle build -->
    <!doctype html>
    <html lang="en-US">
      <head>
        <title>Swagger UI: OAuth2 Redirect</title>
        <%= if script_src_nonce do %>
          <script nonce="<%= script_src_nonce %>">
        <% else %>
          <script>
        <% end %>
          'use strict';
          (function run() {
              var oauth2 = window.opener.swaggerUIRedirectOauth2;
              var sentState = oauth2.state;
              var redirectUrl = oauth2.redirectUrl;
              var isValid, qp, arr;

              if (/code|token|error/.test(window.location.hash)) {
                  qp = window.location.hash.substring(1);
              } else {
                  qp = location.search.substring(1);
              }

              arr = qp.split("&")
              arr.forEach(function (v, i, _arr) { _arr[i] = '"' + v.replace('=', '":"') + '"'; })
              qp = qp ? JSON.parse('{' + arr.join() + '}',
                  function (key, value) {
                      return key === "" ? value : decodeURIComponent(value)
                  }
              ) : {}

              isValid = qp.state === sentState
              var flow = oauth2.auth.schema.get("flow");

              if ((flow === "accessCode" || flow === "authorizationCode") && !oauth2.auth.code) {
                  if (!isValid) {
                      oauth2.errCb({
                          authId: oauth2.auth.name,
                          source: "auth",
                          level: "warning",
                          message: "Authorization may be unsafe, passed state was changed in server Passed state wasn't returned from auth server"
                      });
                  }

                  if (qp.code) {
                      delete oauth2.state;
                      oauth2.auth.code = qp.code;
                      var callbackOpts1 = { auth: oauth2.auth, redirectUrl: redirectUrl };
                      oauth2.callback({ auth: oauth2.auth, redirectUrl: redirectUrl });
                  } else {
                      let oauthErrorMsg
                      if (qp.error) {
                          oauthErrorMsg = "[" + qp.error + "]: " +
                              (qp.error_description ? qp.error_description + ". " : "no accessCode received from the server. ") +
                              (qp.error_uri ? "More info: " + qp.error_uri : "");
                      }

                      oauth2.errCb({
                          authId: oauth2.auth.name,
                          source: "auth",
                          level: "error",
                          message: oauthErrorMsg || "[Authorization failed]: no accessCode received from the server"
                      });
                  }
              } else {
                  // oauth2.auth.state = oauth2.state;
                  var callbackOpts2 = { auth: oauth2.auth, token: qp, isValid: isValid, redirectUrl: redirectUrl };
                  oauth2.callback(callbackOpts2);
              }
              window.close();
          })();
        </script>
      </head>
    </html>
  """

  @doc """
  Initializes the plug.

  ## Options

   * `:csp_nonce_assign_key` - Optional. An assign key to find the CSP nonce value used
     for assets. Supports either `atom()` or a map of type `%{optional(:script) => atom()}`.

  ## Example

      get "/oauth2-redirect.html",
          OpenApiSpex.Plug.SwaggerUIOAuth2Redirect,
          csp_nonce_assign_key: %{script: :script_src_nonce}
  """
  @impl Plug
  def init(opts) when is_list(opts) do
    Map.new(opts)
  end

  @impl Plug
  def call(conn, config) do
    html = render(SwaggerUI.get_nonce(conn, config, :script))

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  require EEx
  EEx.function_from_string(:defp, :render, @html, [:script_src_nonce])
end
