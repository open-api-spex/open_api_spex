defmodule Mix.Tasks.Openapi.Spec.Json do
  @default_filename "openapi.json"
  @moduledoc """
  Serialize the given OpenApi spec module to a JSON file.

  ## Examples

      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec apispec.json
      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec --pretty=true
      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec --no-start-app
      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec --vendor-extensions=false

  ## Command line options

  * `--spec` - The ApiSpec module from which to generate the OpenAPI JSON file

  * `--pretty` - Whether to prettify the generated JSON (defaults to false)

  * `--no-start-app` - Whether need to avoid to start application before generate schema (by default it starts the application)

  * `--vendor-extensions` - Whether to include open_api_spex OpenAPI vendor extensions
    (defaults to true)

  * `--quiet` - Whether to disable output printing (defaults to false)

  * `--filename` - The output filename (defaults to "#{@default_filename}")
  """
  use Mix.Task
  require Mix.Generator

  @impl true
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, switches: [start_app: :boolean])

    Keyword.get(opts, :start_app, true) |> maybe_start_app()
    OpenApiSpex.ExportSpec.call(argv, &encode/2, @default_filename)
  end

  defp maybe_start_app(true), do: Mix.Task.run("app.start")
  defp maybe_start_app(_), do: Mix.Task.run("app.config", preload_modules: true)

  defp encode(spec, %{pretty: pretty}) do
    spec
    |> OpenApiSpex.OpenApi.json_encoder().encode(pretty: pretty)
    |> case do
      {:ok, json} ->
        "#{json}\n"

      {:error, error} ->
        Mix.raise("could not encode #{inspect(spec)}, error: #{inspect(error)}.")
    end
  end
end
