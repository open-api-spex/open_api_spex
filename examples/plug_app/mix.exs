defmodule PlugApp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_app,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:plug_cowboy, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:ecto, "~> 2.2"},
      {:sqlite_ecto2, "~> 2.2"},
      {:jason, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
