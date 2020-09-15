defmodule OpenApiSpex.Plug.Cache do
  @moduledoc """
  Cache for OpenApiSpex

  Settings:

  ```elixir
  config :open_api_spex, :cache_adapter, Module
  ```

  There are already had three cache adapter:
  * `OpenApiSpex.Plug.PersistentTermCache` - default
  * `OpenApiSpex.Plug.AppEnvCache` - if VM not supported `persistent_term`
  * `OpenApiSpex.Plug.NoneCache` - none cache

  If you are constantly modifying specs during development, you can setting
  like this in `dev.exs`:

  ```elixir
  config :open_api_spex, :cache_adapter, OpenApiSpex.Plug.NoneCache
  ```
  """

  alias Plug.Conn

  default_adapter =
    if(function_exported?(:persistent_term, :info, 0)) do
      OpenApiSpex.Plug.PersistentTermCache
    else
      OpenApiSpex.Plug.AppEnvCache
    end

  @default_adapter default_adapter
  @missing_oas_key "Missing private.open_api_spex key in conn. Check that PutApiSpec is being called in the Conn pipeline"

  @callback get(module) :: {OpenApiSpex.OpenApi.t(), map} | nil
  @callback put(module, {OpenApiSpex.OpenApi.t(), map}) :: :ok
  @callback erase(module) :: :ok

  @doc """
  Get cache adapter
  """
  @spec adapter() :: module()
  def adapter do
    Application.get_env(:open_api_spex, :cache_adapter, @default_adapter)
  end

  @doc """
  Only erase cache, put again when plug starting
  """
  @spec refresh() :: :ok
  def refresh do
    adapter = adapter()
    adapter.erase()
  end

  @spec get_spec_and_operation_lookup(Conn.t()) ::
          {spec :: OpenApiSpex.OpenApi.t(),
           operation_lookup :: %{any => OpenApiSpex.Operation.t()}}
  def get_spec_and_operation_lookup(conn) do
    spec_module = spec_module(conn)
    adapter = adapter()
    spec_and_lookup = adapter.get(spec_module)

    if spec_and_lookup do
      spec_and_lookup
    else
      spec_and_lookup = build_spec(spec_module)
      adapter.put(spec_module, spec_and_lookup)
      spec_and_lookup
    end
  end

  @spec build_spec(module) ::
          {OpenApiSpex.OpenApi.t(), %{String.t() => OpenApiSpex.Operation.t()}}
  def build_spec(mod) do
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

  @spec get_and_cache_controller_action(Conn.t(), String.t(), {module, atom}) ::
          OpenApiSpex.Operation.t()
  def get_and_cache_controller_action(conn, operation_id, {controller, action}) do
    spec_module = spec_module(conn)
    adapter = adapter()
    {spec, operation_lookup} = get_spec_and_operation_lookup(conn)
    operation = operation_lookup[operation_id]
    operation_lookup = Map.put(operation_lookup, {controller, action}, operation)
    adapter.put(spec_module, {spec, operation_lookup})
    operation
  end

  @spec spec_module(Conn.t()) :: module
  def spec_module(conn) do
    private_data = Map.get(conn.private, :open_api_spex) || raise @missing_oas_key
    private_data.spec_module
  end
end

defmodule OpenApiSpex.Plug.AppEnvCache do
  @moduledoc false
  @behaviour OpenApiSpex.Plug.Cache

  @impl true
  def get(spec_module) do
    Application.get_env(:open_api_spex, spec_module)
  end

  @impl true
  def put(spec_module, spec) do
    :ok = Application.put_env(:open_api_spex, spec_module, spec)
  end

  @impl true
  def erase(spec_module) do
    Application.delete_env(:open_api_spex, spec_module)
  end
end

if function_exported?(:persistent_term, :info, 0) do
  defmodule OpenApiSpex.Plug.PersistentTermCache do
    @moduledoc false
    @behaviour OpenApiSpex.Plug.Cache

    @impl true
    def get(spec_module) do
      :persistent_term.get(spec_module)
    rescue
      ArgumentError ->
        nil
    end

    @impl true
    def put(spec_module, spec) do
      :ok = :persistent_term.put(spec_module, spec)
    end

    @impl true
    def erase(spec_module) do
      :persistent_term.erase(spec_module)
      :ok
    end
  end
end

defmodule OpenApiSpex.Plug.NoneCache do
  @moduledoc false
  @behaviour OpenApiSpex.Plug.Cache

  @impl true
  def get(_spec_module), do: nil

  @impl true
  def put(_spec_module, _spec), do: :ok

  @impl true
  def erase(_spec_module), do: :ok
end
