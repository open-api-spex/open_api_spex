defmodule OpenApiSpex.Plug.PutApiSpec do
  @moduledoc """
  Module plug that calls a given module to obtain the Api Spec and store it as private in the Conn.

  This allows downstream plugs to use the API spec for casting, validating and rendering.

  ## Options

   - module: A module implementing the `OpenApiSpex.OpenApi` behaviour

  ## Example

      plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  """
  @behaviour Plug
  @cache OpenApiSpex.Plug.Cache.adapter()

  @impl Plug
  def init(opts) do
    opts[:module] ||
      raise "A :module option is required, but none was given to #{__MODULE__}.init/1"
  end

  @impl Plug
  def call(conn, spec_module) do
    # {spec, operation_lookup} =
    _ =
      case @cache.get(spec_module) do
        nil ->
          spec_and_lookup = build_spec(spec_module)
          @cache.put(spec_module, spec_and_lookup)
          spec_and_lookup

        spec_and_lookup ->
          spec_and_lookup
      end

    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:spec_module, spec_module)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  @spec build_spec(module) ::
          {OpenApiSpex.OpenApi.t(), %{String.t() => OpenApiSpex.Operation.t()}}
  defp build_spec(mod) do
    spec = mod.spec()
    operation_lookup = build_operation_lookup(spec)
    {spec, operation_lookup}
  end

  @spec build_operation_lookup(OpenApiSpex.OpenApi.t()) :: %{
          String.t() => OpenApiSpex.Operation.t()
        }
  defp build_operation_lookup(spec = %OpenApiSpex.OpenApi{}) do
    spec
    |> Map.get(:paths)
    |> Stream.flat_map(fn {_name, item} -> Map.values(item) end)
    |> Stream.filter(fn x -> match?(%OpenApiSpex.Operation{}, x) end)
    |> Stream.map(fn operation -> {operation.operationId, operation} end)
    |> Enum.into(%{})
  end
end
