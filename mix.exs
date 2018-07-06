defmodule OpenApiSpex.Mixfile do
  use Mix.Project

  @version "2.2.0"

  def project do
    [
      app: :open_api_spex,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
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
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application, do: [extra_applications: []]

  defp description() do
    "Leverage Open Api Specification 3 (swagger) to document, test, validate and explore your Plug and Phoenix APIs."
  end

  defp package() do
    [
      name: "open_api_spex",
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
      maintainers: ["Mike Buhot (m.buhot@gmail.com)"],
      licenses: ["Mozilla Public License, version 2.0"],
      links: %{"GitHub" => "https://github.com/mbuhot/open_api_spex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:plug, "~> 1.4"},
      {:phoenix, "~> 1.3", only: :test},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end
end
