defmodule OpenApiSpex.Plug.PutApiSpec do
  @moduledoc """
  Module plug that calls a given module to obtain the Api Spec and store it as private in the Conn.

  This allows downstream plugs to use the API spec for casting, validating and rendering.

  ## Example

      plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  """
  @behaviour Plug

  @impl Plug
  def init(opts) do
    module = Keyword.fetch!(opts, :module)

    build_spec(module)
  end

  @impl Plug
  def call(conn, private_data) do
    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  defp build_spec(mod) do
    spec = mod.spec()
    operation_lookup = build_operation_lookup(spec)

    %{spec: spec, operation_lookup: operation_lookup}
  end

  defp build_operation_lookup(spec = %OpenApiSpex.OpenApi{}) do
    spec
    |> Map.get(:paths)
    |> Stream.flat_map(fn {_name, item} -> Map.values(item) end)
    |> Stream.filter(fn x -> match?(%OpenApiSpex.Operation{}, x) end)
    |> Stream.map(fn operation -> {operation.operationId, operation} end)
    |> Enum.into(%{})
  end
end
