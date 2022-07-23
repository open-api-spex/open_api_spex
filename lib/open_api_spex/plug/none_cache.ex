defmodule OpenApiSpex.Plug.NoneCache do
  @moduledoc """
  A cache adapter to disable caching. Intended to be used in development.

  Configure it with:

  ```elixir
  # config/dev.exs
  config :open_api_spex, :cache_adapter, OpenApiSpex.Plug.NoneCache
  ```
  """

  @behaviour OpenApiSpex.Plug.Cache

  @impl true
  def get(_spec_module), do: nil

  @impl true
  def put(_spec_module, _spec), do: :ok

  @impl true
  def erase(_spec_module), do: :ok
end
