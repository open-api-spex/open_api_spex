defmodule OpenApiSpex.OpenApi do
  @moduledoc """
  Defines the `OpenApiSpex.OpenApi.t` type and the behaviour for application modules that
  construct an `OpenApiSpex.OpenApi.t` at runtime.
  """
  alias OpenApiSpex.{
    Extendable,
    Info,
    Server,
    Paths,
    Components,
    SecurityRequirement,
    Tag,
    ExternalDocumentation,
    OpenApi,
    MediaType,
    Schema,
    Example
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

  def json_encoder, do: @json_encoder

  for encoder <- [Poison.Encoder, Jason.Encoder] do
    if Code.ensure_loaded?(encoder) do
      defimpl encoder do
        def encode(api_spec = %OpenApi{}, options) do
          api_spec
          |> to_json()
          |> unquote(encoder).encode(options)
        end

        defp to_json(%Regex{source: source}), do: source

        defp to_json(%object{} = value) when object in [MediaType, Schema, Example] do
          value
          |> Extendable.to_map()
          |> Stream.map(fn
            {:value, v} when object == Example -> {"value", to_json_example(v)}
            {:example, v} -> {"example", to_json_example(v)}
            {k, v} -> {to_string(k), to_json(v)}
          end)
          |> Stream.filter(fn
            {_, nil} -> false
            _ -> true
          end)
          |> Enum.into(%{})
        end

        defp to_json(value = %{__struct__: _}) do
          value
          |> Extendable.to_map()
          |> to_json()
        end

        defp to_json(value) when is_map(value) do
          value
          |> Stream.map(fn {k, v} -> {to_string(k), to_json(v)} end)
          |> Stream.filter(fn
            {_, nil} -> false
            _ -> true
          end)
          |> Enum.into(%{})
        end

        defp to_json(value) when is_list(value) do
          Enum.map(value, &to_json/1)
        end

        defp to_json(nil), do: nil
        defp to_json(true), do: true
        defp to_json(false), do: false
        defp to_json(value) when is_atom(value), do: to_string(value)
        defp to_json(value), do: value

        defp to_json_example(value = %{__struct__: _}) do
          value
          |> Extendable.to_map()
          |> to_json_example()
        end

        defp to_json_example(value) when is_map(value) do
          value
          |> Stream.map(fn {k, v} -> {to_string(k), to_json_example(v)} end)
          |> Enum.into(%{})
        end

        defp to_json_example(value) when is_list(value) do
          Enum.map(value, &to_json_example/1)
        end

        defp to_json_example(value), do: to_json(value)
      end
    end
  end

  def from_map(map) do
    OpenApi.Decode.decode(map)
  end
end
