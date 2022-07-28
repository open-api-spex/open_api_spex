defmodule OpenApiSpex.Plug.Cache do
  @moduledoc """
  Cache for OpenApiSpex API specs.

  Settings:

  ```elixir
  config :open_api_spex, :cache_adapter, Module
  ```

  There are three cache implementations:

  * `OpenApiSpex.Plug.PersistentTermCache` - default
  * `OpenApiSpex.Plug.AppEnvCache` - for VMs that don't support `persistent_term`
  * `OpenApiSpex.Plug.NoneCache` - none cache

  If you are constantly modifying specs during development, you can configure the cache adapter
  in `dev.exs` as follows to disable caching:

  ```elixir
  config :open_api_spex, :cache_adapter, OpenApiSpex.Plug.NoneCache
  ```
  """

  alias OpenApiSpex.OpenApi

  default_adapter =
    if function_exported?(:persistent_term, :info, 0) do
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
