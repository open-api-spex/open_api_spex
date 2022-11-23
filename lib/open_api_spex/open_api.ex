defmodule OpenApiSpex.OpenApi do
  @moduledoc """
  Defines the `OpenApiSpex.OpenApi.t` type and the behaviour for application modules that
  construct an `OpenApiSpex.OpenApi.t` at runtime.
  """
  alias OpenApiSpex.{
    Components,
    Example,
    Extendable,
    ExternalDocumentation,
    Info,
    MediaType,
    OpenApi,
    Paths,
    Schema,
    SecurityRequirement,
    Server,
    Tag
  }

  @enforce_keys [:info, :paths]
  defstruct openapi: "3.0.0",
            info: nil,
            servers: [],
            paths: nil,
            components: nil,
            security: [],
            tags: [],
            externalDocs: nil,
            extensions: nil

  @typedoc """
  [OpenAPI Object](https://swagger.io/specification/#oasObject)

  This is the root document object of the OpenAPI document.
  """
  @type t :: %OpenApi{
          openapi: String.t(),
          info: Info.t(),
          servers: [Server.t()] | nil,
          paths: Paths.t(),
          components: Components.t() | nil,
          security: [SecurityRequirement.t()] | nil,
          tags: [Tag.t()] | nil,
          externalDocs: ExternalDocumentation.t() | nil,
          extensions: %{String.t() => any()} | nil
        }

  @doc """
  A spec/0 callback function is required for use with the `OpenApiSpex.Plug.PutApiSpec` plug.

  ## Example

      @impl OpenApiSpex.OpenApi
      def spec do
        %OpenApi{
          servers: [
            # Populate the Server info from a phoenix endpoint
            Server.from_endpoint(MyAppWeb.Endpoint)
          ],
          info: %Info{
            title: "My App",
            version: "1.0"
          },
          # populate the paths from a phoenix router
          paths: Paths.from_router(MyAppWeb.Router)
        }
        |> OpenApiSpex.resolve_schema_modules() # discover request/response schemas from path specs
      end
  """
  @callback spec() :: t

  @json_encoder Enum.find([Jason, Poison], &Code.ensure_loaded?/1)
  @yaml_encoder nil
  @vendor_extensions ~w(
    x-struct
    x-validate
    x-parameter-content-parsers
  )

  def json_encoder, do: @json_encoder

  for encoder <- [Poison.Encoder, Jason.Encoder] do
    if Code.ensure_loaded?(encoder) do
      defimpl encoder do
        def encode(api_spec = %OpenApi{}, options) do
          api_spec
          |> OpenApi.to_map()
          |> unquote(encoder).encode(options)
        end
      end
    end
  end

  if Code.ensure_loaded?(Ymlr) do
    defmodule YmlrEncoder do
      @moduledoc false

      def encode(api_spec = %{}, _options) do
        api_spec
        |> OpenApi.to_map()
        |> Ymlr.document()
      end
    end

    @yaml_encoder YmlrEncoder
  end

  def yaml_encoder, do: @yaml_encoder

  def to_map(value), do: to_map(value, [])
  def to_map(%Regex{source: source}, _opts), do: source

  def to_map(%object{} = value, opts) when object in [MediaType, Schema, Example] do
    value
    |> Extendable.to_map()
    |> Stream.map(fn
      {:value, v} when object == Example -> {"value", to_map_example(v, opts)}
      {:example, v} -> {"example", to_map_example(v, opts)}
      {:required, []} when object == Schema -> {"required", nil}
      {k, v} -> {to_string(k), to_map(v, opts)}
    end)
    |> Stream.filter(fn
      {:required, []} when object == Schema -> false
      {k, _} when k in @vendor_extensions -> opts[:vendor_extensions]
      {_, nil} -> false
      _ -> true
    end)
    |> Enum.into(%{})
  end

  def to_map(value = %{__struct__: _}, opts) do
    value
    |> Extendable.to_map()
    |> to_map(opts)
  end

  def to_map(value, opts) when is_map(value) do
    value
    |> Stream.map(fn {k, v} -> {to_string(k), to_map(v, opts)} end)
    |> Stream.filter(fn
      {_, nil} -> false
      _ -> true
    end)
    |> Enum.into(%{})
  end

  def to_map(value, opts) when is_list(value) do
    Enum.map(value, &to_map(&1, opts))
  end

  def to_map(nil, _opts), do: nil
  def to_map(true, _opts), do: true
  def to_map(false, _opts), do: false
  def to_map(value, _opts) when is_atom(value), do: to_string(value)
  def to_map(value, _opts), do: value

  defp to_map_example(value = %{__struct__: _}, opts) do
    value
    |> Extendable.to_map()
    |> to_map_example(opts)
  end

  defp to_map_example(value, opts) when is_map(value) do
    value
    |> Stream.map(fn {k, v} -> {to_string(k), to_map_example(v, opts)} end)
    |> Enum.into(%{})
  end

  defp to_map_example(value, opts) when is_list(value) do
    Enum.map(value, &to_map_example(&1, opts))
  end

  defp to_map_example(value, opts), do: to_map(value, opts)

  def from_map(map) do
    OpenApi.Decode.decode(map)
  end
end
