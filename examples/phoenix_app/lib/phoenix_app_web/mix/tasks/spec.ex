defmodule Mix.Tasks.PhoenixAppWeb.OpenApiSpec do
  def run([]) do
    PhoenixAppWeb.ApiSpec.spec()
    |> Jason.encode!(pretty: true, maps: :strict)
    |> (&File.write!("openapi3_v1.0.json", &1)).()
  end
end
