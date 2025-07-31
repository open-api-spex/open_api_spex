defmodule Mix.Tasks.Openapi.StaticDocs do
  @shortdoc "Generate a static file that renders the OpenAPI spec using the Swagger UI"
  @moduledoc """
  Generate a static file that renders the OpenAPI spec using the Swagger UI. Uses
  assets from https://unpkg.com/swagger-ui-dist.

  ## Examples

      $ mix openapi.static_docs --spec PhoenixAppWeb.ApiSpec --output-file swagger.md
      $ mix openapi.static_docs --spec PhoenixAppWeb.ApiSpec --output-file swagger.md --swagger-version 4.4.1

  ## Usage with ExDoc

  To use with ExDoc, you can add the following to your `mix.exs` file:

  ```elixir
  def docs do
    [
      extras: ["guides/swagger.md"]
    ]
  end

  def aliases do
    [
      "docs": [
        "cmd mkdir -p guides/",
        "openapi.static_docs --spec PhoenixAppWeb.ApiSpec --output-file guides/swagger.md --swagger-version 4.4.0",
        "docs"
      ]
    ]
  end
  ```

  ## Command line options

  Accepts all the same options as `Mix.Tasks.Openapi.Spec.Json` plus:

  * `--output-file` - The file to write the static file to (defaults to `swagger.md`)

  * `--swagger-version` - The version of the Swagger UI to use (defaults to `4.4.1`)
  """
  use Mix.Task

  require Mix.Generator

  alias Mix.Tasks.Openapi.Spec.Json

  @recursive true
  @default_static_filename "swagger.md"
  @default_swagger_version "4.4.1"

  @static_template """
  # <%= spec_name %>

  <head>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@<%= swagger_version %>/swagger-ui.css" />
  </head>

  <body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@<%= swagger_version %>/swagger-ui-bundle.js" crossorigin></script>
  <script src="https://unpkg.com/swagger-ui-dist@<%= swagger_version %>/swagger-ui-standalone-preset.js" crossorigin></script>
  <script>
    window.onload = () => {
      window.ui = SwaggerUIBundle({
        spec: <%= json_spec %>,
        dom_id: '#swagger-ui',
      });
    };
  </script>
  </body>
  """

  @flags [
    output_file: :string,
    swagger_version: :string,
    spec: :string
  ]

  @impl true
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, switches: @flags)

    json_spec_filename = Json.run(argv)

    output_file = Keyword.get(opts, :output_file, @default_static_filename)
    swagger_version = Keyword.get(opts, :swagger_version, @default_swagger_version)

    json_spec = File.read!(json_spec_filename)

    rendered_template =
      EEx.eval_string(@static_template,
        spec_name: opts[:spec],
        json_spec: json_spec,
        swagger_version: swagger_version
      )

    Mix.Generator.create_file(output_file, rendered_template, force: true, quiet: true)
  end
end
