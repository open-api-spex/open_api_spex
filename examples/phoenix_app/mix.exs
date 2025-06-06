defmodule PhoenixApp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_app,
      version: "0.0.1",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PhoenixApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases() do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      spec: ["openapi.spec.json  --spec PhoenixAppWeb.ApiSpec \"priv/static/swagger.json\""],
      "spec.yaml": ["openapi.spec.yaml --spec PhoenixAppWeb.ApiSpec \"priv/static/swagger.yaml\""]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:open_api_spex, path: "../../"},
      {:ecto, "~> 3.11"},
      {:httpoison, "~> 2.2"},
      {:ecto_sqlite3, "~> 0.16"},
      {:phoenix, "~> 1.4"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:ymlr, "~> 5.0"},
      {:dialyxir, "1.0.0-rc.6", only: [:dev], runtime: false}
    ]
  end
end
