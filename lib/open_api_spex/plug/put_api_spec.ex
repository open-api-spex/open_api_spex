defmodule OpenApiSpex.Plug.PutApiSpec do
  @moduledoc """
  Module plug that calls a given module to obtain the Api Spec and store it as private in the Conn.

  This allows downstream plugs to use the API spec for casting, validating and rendering.

  ## Options

   - module: A module implementing the `OpenApiSpex.OpenApi` behaviour

  ## Example

      plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  """
  @behaviour Plug

  @impl Plug
  def init(opts) do
    opts[:module] ||
      raise "A :module option is required, but none was given to #{__MODULE__}.init/1"
  end

  @impl Plug
  def call(conn, spec_module) do
    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:spec_module, spec_module)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end
end
