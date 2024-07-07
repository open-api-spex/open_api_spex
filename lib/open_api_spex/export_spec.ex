defmodule OpenApiSpex.ExportSpec do
  @moduledoc """
  Export spec in specified encoding
  """
  require Mix.Generator

  defmodule Options do
    @moduledoc false

    defstruct filename: nil,
              spec: nil,
              pretty: false,
              check: false,
              vendor_extensions: true,
              quiet: false
  end

  def call(argv, encode_spec, default_filename) do
    opts = parse_options(argv, default_filename)

    encoded_spec =
      opts
      |> generate_spec()
      |> encode_spec.(opts)

    if opts.check do
      check_spec(encoded_spec, opts)
    else
      write_spec(encoded_spec, opts)
    end
  end

  defp generate_spec(%{spec: spec, vendor_extensions: vendor_extensions}) do
    case Code.ensure_compiled(spec) do
      {:module, _} ->
        if function_exported?(spec, :spec, 0) do
          OpenApiSpex.OpenApi.to_map(spec.spec(), vendor_extensions: vendor_extensions)
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

  defp parse_options(argv, default_filename) do
    parse_options = [
      strict: [
        spec: :string,
        endpoint: :string,
        pretty: :boolean,
        check: :boolean,
        vendor_extensions: :boolean,
        quiet: :boolean
      ]
    ]

    {opts, args, _} = OptionParser.parse(argv, parse_options)

    %Options{
      filename: args |> List.first() || default_filename,
      spec: find_spec(opts),
      pretty: Keyword.get(opts, :pretty, false),
      check: Keyword.get(opts, :check, false),
      vendor_extensions: Keyword.get(opts, :vendor_extensions, true),
      quiet: Keyword.get(opts, :quiet, false)
    }
  end

  defp check_spec(content, opts) do
    unless content == File.read!(opts.filename) do
      Mix.raise("The OpenAPI spec file does not match the generated spec:\n\n#{content}")
    end
  end

  defp write_spec(content, opts) do
    case Path.dirname(opts.filename) do
      "." -> true
      dir -> Mix.Generator.create_directory(dir, quiet: opts.quiet)
    end

    Mix.Generator.create_file(opts.filename, content, force: true, quiet: opts.quiet)
  end

  defp find_spec(opts) do
    if spec = Keyword.get(opts, :spec) do
      Module.concat([spec])
    else
      Mix.raise("No spec available. Please pass a spec with the --spec option")
    end
  end
end
