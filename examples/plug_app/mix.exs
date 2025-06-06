defmodule PlugApp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_app,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PlugApp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:open_api_spex, path: "../../"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.0"},
      {:ecto, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.16"},
      {:jason, "~> 1.0"},
      {:ymlr, "~> 5.0"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      spec: ["openapi.spec.json  --spec PlugApp.ApiSpec \"priv/static/swagger.json\""],
      "spec.yaml": ["openapi.spec.yaml --spec PlugApp.ApiSpec \"priv/static/swagger.yaml\""]
    ]
  end
end
