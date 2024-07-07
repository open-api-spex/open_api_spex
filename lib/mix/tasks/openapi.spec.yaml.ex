defmodule Mix.Tasks.Openapi.Spec.Yaml do
  @default_filename "openapi.yaml"
  @moduledoc """
  Serialize the given OpenApi spec module to a YAML file.

  ## Examples

      $ mix openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec apispec.yaml
      $ mix openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec --check=true
      $ mix openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec --start-app=false
      $ mix openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec --vendor-extensions=false

  ## Command line options

  * `--spec` - The ApiSpec module from which to generate the OpenAPI YAML file

  * `--check` - Whether to only compare the generated YAML with the spec file (defaults to false)

  * `--start-app` - Whether to start the application before generating the schema (defaults to true)

  * `--vendor-extensions` - Whether to include open_api_spex OpenAPI vendor extensions
    (defaults to true)

  * `--quiet` - Whether to disable output printing (defaults to false)

  * `--filename` - The output filename (defaults to "#{@default_filename}")
  """
  use Mix.Task
  require Mix.Generator

  @dialyzer {:nowarn_function, encoder: 0}

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [start_app: :boolean])

    Keyword.get(opts, :start_app, true) |> maybe_start_app()
    OpenApiSpex.ExportSpec.call(argv, &encode/2, @default_filename)
  end

  defp maybe_start_app(true), do: Mix.Task.run("app.start")
  defp maybe_start_app(_), do: Mix.Task.run("app.config", preload_modules: true)

  defp encode(spec, opts) do
    spec
    |> encoder().encode(opts)
    |> case do
      {:ok, yaml} ->
        yaml

      {:error, error} ->
        Mix.raise("could not encode #{inspect(spec)}, error: #{inspect(error)}.")
    end
  end

  defp encoder do
    OpenApiSpex.OpenApi.yaml_encoder() ||
      Mix.raise(
        "could not load YAML encoder, please add one of supported encoders to dependencies."
      )
  end
end
