if function_exported?(:persistent_term, :info, 0) do
  defmodule OpenApiSpex.Plug.PersistentTermCache do
    @moduledoc "A cache leveraging `:persistent_term`."

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
