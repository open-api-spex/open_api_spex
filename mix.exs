defmodule OpenApiSpex.Mixfile do
  use Mix.Project

  @version "3.10.0"

  def project do
    [
      app: :open_api_spex,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      consolidate_protocols: Mix.env() != :test,
      source_url: "https://github.com/open-api-spex/open_api_spex",
      homepage_url: "https://github.com/open-api-spex/open_api_spex",
      docs: [extras: ["README.md"], main: "readme", source_ref: "v#{@version}"],
      dialyzer: [
        plt_add_apps: [:mix, :jason, :poison],
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
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md", ".formatter.exs"],
      maintainers: [
        "Mike Buhot (m.buhot@gmail.com)",
        "Moxley Stratton (moxley.stratton@gmail.com)",
        "Pierre Fenoll (pierrefenoll@gmail.com)"
      ],
      licenses: ["Mozilla Public License, version 2.0"],
      links: %{"GitHub" => "https://github.com/open-api-spex/open_api_spex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:jason, "~> 1.0", optional: true},
      {:phoenix, "~> 1.3", only: [:dev, :test]},
      {:plug, "~> 1.7"},
      {:poison, "~> 3.1", optional: true}
    ]
  end
end
