defmodule Mix.Tasks.Openapi.Spec.Json do
  @moduledoc """
  Serialize the given OpenApi spec module to a JSON file.

  ## Examples

      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec apispec.json
      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec --pretty=true
      $ mix openapi.spec.json --spec PhoenixAppWeb.ApiSpec --vendor-extensions=false

  ## Command line options

  * `--spec` - The ApiSpec module from which to generate the OpenAPI JSON file

  * `--pretty` - Whether to prettify the generated JSON (defaults to false)

  * `--vendor-extensions` - Whether to include open_api_spex OpenAPI vendor extensions
    (defaults to true)

  """
  use Mix.Task
  require Mix.Generator

  @default_filename "openapi.json"

  @impl true
  def run(argv) do
    Mix.Task.run("app.start")
    OpenApiSpex.ExportSpec.call(argv, &encode/2, @default_filename)
  end

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
