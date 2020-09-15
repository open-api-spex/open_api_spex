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

  alias OpenApiSpex.OpenApi

  default_adapter =
    if(function_exported?(:persistent_term, :info, 0)) do
      OpenApiSpex.Plug.PersistentTermCache
    else
      OpenApiSpex.Plug.AppEnvCache
    end

  @default_adapter default_adapter

  @callback get(module) :: {OpenApi.t(), map} | nil
  @callback put(module, {OpenApi.t(), map}) :: :ok
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
