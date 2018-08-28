defmodule Mix.Tasks.PhoenixAppWeb.OpenApiSpec do
  def run([]) do
    PhoenixAppWeb.ApiSpec.spec()
    |> Poison.encode!(pretty: true, strict_keys: true)
    |> (&File.write!("openapi3_v1.0.json", &1)).()
  end
end
