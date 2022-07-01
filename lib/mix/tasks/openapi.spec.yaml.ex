defmodule Mix.Tasks.Openapi.Spec.Yaml do
  @moduledoc """
  Serialize the given OpenApi spec module to a YAML file.

  ## Examples

      $ mix openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec apispec.yaml
      $ mix openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec --vendor-extensions=false

  ## Command line options

  * `--spec` - The ApiSpec module from which to generate the OpenAPI YAML file

  * `--vendor-extensions` - Whether to include open_api_spex OpenAPI vendor extensions
    (defaults to true)

  """
  use Mix.Task
  require Mix.Generator

  @default_filename "openapi.yaml"

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    OpenApiSpex.ExportSpec.call(argv, &encode/2, @default_filename)
  end

  defp encode(spec, opts) do
    spec
    |> OpenApiSpex.OpenApi.yaml_encoder().encode(opts)
    |> case do
      {:ok, yaml} ->
        yaml

      {:error, error} ->
        Mix.raise("could not encode #{inspect(spec)}, error: #{inspect(error)}.")
    end
  end
end
