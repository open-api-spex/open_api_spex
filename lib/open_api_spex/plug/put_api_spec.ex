defmodule OpenApiSpex.Plug.PutApiSpec do
  @moduledoc """
  Module plug that calls a given module to obtain the Api Spec and store it as private in the Conn.

  This allows downstream plugs to use the API spec for casting, validating and rendering.

  ## Example

      plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  """
  @behaviour Plug

  @impl Plug
  def init([module: _spec_module] = opts) do
    if function_exported?(:persistent_term, :info, 0) do
      {opts[:module], :term}
    else
      {opts[:module], :env}
    end
  end

  @impl Plug
  def call(conn, {spec_module, storage}) do
    {spec, operation_lookup} =
      fetch_spec(spec_module, storage)

    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:spec, spec)
      |> Map.put(:operation_lookup, operation_lookup)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  @spec build_spec(module) :: {OpenApiSpex.OpenApi.t, %{String.t => OpenApiSpex.Operation.t}}
  defp build_spec(mod) do
    spec = mod.spec()
    operation_lookup = build_operation_lookup(spec)
    {spec, operation_lookup}
  end

  @spec build_operation_lookup(OpenApiSpex.OpenApi.t) :: %{String.t => OpenApiSpex.Operation.t}
  defp build_operation_lookup(spec = %OpenApiSpex.OpenApi{}) do
    spec
    |> Map.get(:paths)
    |> Stream.flat_map(fn {_name, item} -> Map.values(item) end)
    |> Stream.filter(fn x -> match?(%OpenApiSpex.Operation{}, x) end)
    |> Stream.map(fn operation -> {operation.operationId, operation} end)
    |> Enum.into(%{})
  end

  defp fetch_spec(spec_module, :term) do
    try do
      :persistent_term.get(spec_module)
    rescue
      ArgumentError ->
        term_not_found()
        spec = build_spec(spec_module)
        :ok = :persistent_term.put(spec_module, spec)
        spec
    end
  end

  defp fetch_spec(spec_module, :env) do
    case Application.get_env(:open_api_spex, spec_module) do
      nil ->
        spec = build_spec(spec_module)
        Application.put_env(:open_api_spex, spec_module, spec)
        spec
      spec -> spec
    end
  end

  defp term_not_found do
    if Application.get_env(:open_api_spex, :persistent_term_warn, false) do
      IO.warn("Warning: the OpenApiSpec spec was deleted from persistent terms. This can cause serious issues.")
    else
      Application.put_env(:open_api_spex, :persistent_term, true)
    end
  end
end
