defmodule OpenApiSpex.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :open_api_spex,
      version: "1.0.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      source_url: "https://github.com/mbuhot/open_api_spex",
      homepage_url: "https://github.com/mbuhot/open_api_spex",
      docs: [extras: ["README.md"], main: "readme", source_ref: "v#{@version}"],
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :apps_direct,
        flags: ["-Werror_handling", "-Wno_unused", "-Wunmatched_returns", "-Wunderspecs"],
        remove_defaults: [:unknown]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, ">= 0.0.0"},
      {:plug, ">= 0.0.0"},
      {:phoenix, "~> 1.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
