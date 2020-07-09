defmodule Mix.Tasks.Openapi.Spec.Json do
  @moduledoc """
  Serialize the given OpenApi spec module to a json file.
  """
  use Mix.Task
  require Mix.Generator

  @default_filename "openapi.json"

  defmodule Options do
    @moduledoc false

    defstruct filename: nil, spec: nil, json_codec: nil, endpoint: nil, pretty: false
  end

  @impl true
  def run(argv) do
    opts = parse_options(argv)

    with :ok <- maybe_start_endpoint(opts),
         {:ok, content} <- generate_spec(opts) do
      write_spec(content, opts.filename)
    else
      {:error, error} -> raise error
    end
  end

  def maybe_start_endpoint(%{endpoint: nil}) do
    :ok
  end

  def maybe_start_endpoint(options) do
    if function_exported?(options.endpoint, :start_link, 0) do
      case options.endpoint.start_link() do
        {:ok, _} ->
          :ok

        _ ->
          {:error, "Couldn't start endpoint"}
      end
    else
      {:error, "Unvalid Enpoint module provided"}
    end
  end

  def generate_spec(options) do
    case Code.ensure_loaded(options.spec) do
      {:module, spec} ->
        if function_exported?(spec, :spec, 0) do
          {:ok, spec.spec() |> options.json_codec.encode!(pretty: options.pretty)}
        else
          {:error, "Spec do not export spec callback"}
        end

      {:error, :nofile} ->
        {:error, "Not a valid spec"}
    end
  end

  defp parse_options(argv) do
    parse_options = [
      strict: [spec: :string, endpoint: :string, json_codec: :string, pretty: :boolean]
    ]

    {opts, args, _} = OptionParser.parse(argv, parse_options)

    %Options{
      filename: args |> List.first() || @default_filename,
      spec: find_spec(opts),
      endpoint: maybe_endpoint_as_atom(opts),
      json_codec: json_codec_as_atom(opts),
      pretty: Keyword.get(opts, :pretty, false)
    }
  end

  defp maybe_endpoint_as_atom(opts) do
    if endpoint = Keyword.get(opts, :endpoint) do
      Module.concat([endpoint])
    end
  end

  defp json_codec_as_atom(opts) do
    if codec = Keyword.get(opts, :json_codec) do
      Module.safe_concat([codec])
    else
      Jason
    end
  end

  defp find_spec(opts) do
    if spec = Keyword.get(opts, :spec) do
      Module.concat([spec])
    else
      raise "No --spec given"
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
