defmodule OpenApiSpex.Plug.Cache do
  @moduledoc false

  @callback get(module) :: {OpenApiSpex.OpenApi.t(), map} | nil
  @callback put(module, {OpenApiSpex.OpenApi.t(), map}) :: :ok

  @spec adapter() :: OpenApiSpex.Plug.AppEnvCache | OpenApiSpex.Plug.PersistentTermCache
  def adapter do
    if function_exported?(:persistent_term, :info, 0) do
      OpenApiSpex.Plug.PersistentTermCache
    else
      OpenApiSpex.Plug.AppEnvCache
    end
  end
end

defmodule OpenApiSpex.Plug.AppEnvCache do
  @moduledoc false
  @behaviour OpenApiSpex.Plug.Cache

  @impl OpenApiSpex.Plug.Cache
  def get(spec_module) do
    Application.get_env(:open_api_spex, spec_module)
  end

  @impl OpenApiSpex.Plug.Cache
  def put(spec_module, spec) do
    :ok = Application.put_env(:open_api_spex, spec_module, spec)
  end
end

if function_exported?(:persistent_term, :info, 0) do
  defmodule OpenApiSpex.Plug.PersistentTermCache do
    @moduledoc false
    @behaviour OpenApiSpex.Plug.Cache

    @impl OpenApiSpex.Plug.Cache
    def get(spec_module) do
      :persistent_term.get(spec_module)
    rescue
      ArgumentError ->
        nil
    end

    @impl OpenApiSpex.Plug.Cache
    def put(spec_module, spec) do
      :ok = :persistent_term.put(spec_module, spec)
    end
  end
end
