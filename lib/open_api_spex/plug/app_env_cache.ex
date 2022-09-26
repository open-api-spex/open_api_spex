defmodule OpenApiSpex.Plug.AppEnvCache do
  @moduledoc "A cache implementation leveraging Application env."

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
