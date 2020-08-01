defmodule Mix.Tasks.Openapi.Spec.Json do
  @moduledoc """
  Serialize the given OpenApi spec module to a json file.
  """
  use Mix.Task
  require Mix.Generator

  @default_filename "openapi.json"

  defmodule Options do
    @moduledoc false

    defstruct filename: nil, spec: nil, pretty: false
  end

  @impl true
  def run(argv) do
    Mix.Task.run("app.start")
    opts = parse_options(argv)
    content = generate_spec(opts)
    write_spec(content, opts.filename)
  end

  def generate_spec(%{spec: spec, pretty: pretty}) do
    case Code.ensure_compiled(spec) do
      {:module, _} ->
        if function_exported?(spec, :spec, 0) do
          json_encoder = OpenApiSpex.OpenApi.json_encoder()
          spec = spec.spec()

          case json_encoder.encode(spec, pretty: pretty) do
            {:ok, json} ->
              json

            {:error, error} ->
              Mix.raise("could not encode #{inspect(spec)}, error: #{inspect(error)}.")
          end
        else
          Mix.raise(
            "module #{inspect(spec)} is not a OpenApiSpex.Spec. " <>
              "Please pass a spec with the --spec option."
          )
        end

      {:error, error} ->
        Mix.raise(
          "could not load #{inspect(spec)}, error: #{inspect(error)}. " <>
            "Please pass a spec with the --spec option."
        )
    end
  end

  defp parse_options(argv) do
    parse_options = [strict: [spec: :string, endpoint: :string, pretty: :boolean]]
    {opts, args, _} = OptionParser.parse(argv, parse_options)

    %Options{
      filename: args |> List.first() || @default_filename,
      spec: find_spec(opts),
      pretty: Keyword.get(opts, :pretty, false)
    }
  end

  defp find_spec(opts) do
    if spec = Keyword.get(opts, :spec) do
      Module.concat([spec])
    else
      Mix.raise("No spec available. Please pass a spec with the --spec option")
    end
  end

  defp write_spec(content, filename) do
    case Path.dirname(filename) do
      "." -> true
      dir -> Mix.Generator.create_directory(dir)
    end

    Mix.Generator.create_file(filename, content, force: true)
  end
end
