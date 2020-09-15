defmodule OpenApiSpex.Plug.PutApiSpec do
  @moduledoc """
  Module plug that calls a given module to obtain the Api Spec and store it as private in the Conn.

  This allows downstream plugs to use the API spec for casting, validating and rendering.

  ## Options

   - module: A module implementing the `OpenApiSpex.OpenApi` behaviour

  ## Example

      plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  """
  alias OpenApiSpex.OpenApi

  @behaviour Plug

  @cache OpenApiSpex.Plug.Cache.adapter()
  @missing_oas_key "Missing private.open_api_spex key in conn. Check that PutApiSpec is being called in the Conn pipeline"

  @impl Plug
  def init(opts) do
    opts[:module] ||
      raise "A :module option is required, but none was given to #{__MODULE__}.init/1"
  end

  @impl Plug
  def call(conn, spec_module) do
    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:spec_module, spec_module)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  @spec get_spec_and_operation_lookup(Conn.t()) ::
          {spec :: OpenApi.t(), operation_lookup :: %{any => Operation.t()}}
  def get_spec_and_operation_lookup(conn) do
    spec_module = spec_module(conn)
    spec_and_lookup = @cache.get(spec_module)

    if spec_and_lookup do
      spec_and_lookup
    else
      spec = spec_module.spec()
      operation_lookup = build_operation_lookup(spec)
      spec_and_lookup = {spec, operation_lookup}
      @cache.put(spec_module, spec_and_lookup)
      spec_and_lookup
    end
  end

  @spec get_and_cache_controller_action(Conn.t(), String.t(), {module, atom}) ::
          Operation.t()
  def get_and_cache_controller_action(conn, operation_id, {controller, action}) do
    spec_module = spec_module(conn)
    {spec, operation_lookup} = get_spec_and_operation_lookup(conn)
    operation = operation_lookup[operation_id]
    operation_lookup = Map.put(operation_lookup, {controller, action}, operation)
    @cache.put(spec_module, {spec, operation_lookup})
    operation
  end

  @spec spec_module(Conn.t()) :: module
  def spec_module(conn) do
    private_data = Map.get(conn.private, :open_api_spex) || raise @missing_oas_key
    private_data.spec_module
  end

  @spec build_operation_lookup(OpenApi.t()) :: %{
          String.t() => OpenApiSpex.Operation.t()
        }
  defp build_operation_lookup(%OpenApi{} = spec) do
    spec
    |> Map.get(:paths)
    |> Stream.flat_map(fn {_name, item} -> Map.values(item) end)
    |> Stream.filter(fn x -> match?(%OpenApiSpex.Operation{}, x) end)
    |> Stream.map(fn operation -> {operation.operationId, operation} end)
    |> Enum.into(%{})
  end
end
