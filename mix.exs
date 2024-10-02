defmodule OpenApiSpex.Mixfile do
  use Mix.Project

  @source_url "https://github.com/open-api-spex/open_api_spex"
  @version "3.21.2"

  def project do
    [
      app: :open_api_spex,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      package: package(),
      deps: deps(),
      docs: docs(),
      dialyzer: dialyzer(),
      test_coverage: [
        ignore_modules: [
          ~r/OpenApiSpexTest\./,
          ~r/OpenApiSpex.Extendable\./,
          ~r/Poison.Encoder\./
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application, do: [extra_applications: []]

  defp package() do
    [
      name: "open_api_spex",
      description:
        "Leverage Open Api Specification 3 (swagger) to document, " <>
          "test, validate and explore your Plug and Phoenix APIs.",
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "ROADMAP.md",
        ".formatter.exs"
      ],
      maintainers: [
        "Mike Buhot (m.buhot@gmail.com)",
        "Moxley Stratton (moxley.stratton@gmail.com)",
        "Pierre Fenoll (pierrefenoll@gmail.com)",
        "Dimitris Zorbas (dimitrisplusplus@gmail.com)"
      ],
      licenses: ["MPL-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/open_api_spex/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.0", optional: true},
      {:decimal, "~> 1.0 or ~> 2.0", optional: true},
      {:phoenix, "~> 1.3", only: [:dev, :test]},
      {:plug, "~> 1.7"},
      {:poison, "~> 3.0 or ~> 4.0 or ~> 5.0 or ~> 6.0", optional: true},
      {:ymlr, "~> 2.0 or ~> 3.0 or ~> 4.0 or ~> 5.0", optional: true}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "ROADMAP.md",
        {:LICENSE, [title: "License"]},
        "README.md"
      ],
      main: "readme",
      homepage_url: @source_url,
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: ~w(
        ex_unit
        jason
        mix
        poison
        ymlr
      )a
    ]
  end
end
