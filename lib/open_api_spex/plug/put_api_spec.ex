defmodule OpenApiSpex.Plug.PutApiSpec do
  @moduledoc """
  Module plug that calls a given module to obtain the Api Spec and store it as private in the Conn.

  This allows downstream plugs to use the API spec for casting, validating and rendering.

  ## Example

      plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  """
  @behaviour Plug

  @impl Plug
  def init(opts = [module: _mod]), do: opts

  @impl Plug
  def call(conn, module: mod) do
    {spec, operation_lookup} =
      case Application.get_env(:open_api_spex, mod) do
        nil -> build_spec(mod)
        cached -> cached
      end

    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:spec, spec)
      |> Map.put(:operation_lookup, operation_lookup)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  @spec build_spec(module) ::
          {OpenApiSpex.OpenApi.t(), %{String.t() => OpenApiSpex.Operation.t()}}
  defp build_spec(mod) do
    spec = mod.spec()
    operation_lookup = build_operation_lookup(spec)
    Application.put_env(:open_api_spex, mod, {spec, operation_lookup})
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
end
