defmodule Pote.MixProject do
  use Mix.Project

  @version "2.1.0"

  def project do
    [
      app: :pote,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Pote",
      description:
        "Colorimetry and theme/palette management library for Elixir - parse, convert, harmonize, and render colors across multiple color spaces.",
      source_url: "https://github.com/Lorenzo-SF/pote",
      homepage_url: "https://github.com/Lorenzo-SF/pote",
      package: [
        name: :pote,
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/Lorenzo-SF/pote"},
        maintainers: ["Lorenzo Sánchez"]
      ],
      docs: docs(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "docs/batamantaman_pote.png",
      source_url: "https://github.com/Lorenzo-SF/pote",
      homepage_url: "https://github.com/Lorenzo-SF/pote",
      extras: ["README.md", "docs/README.es.md", "LICENSE.md"],
      groups_for_modules: [
        Core: [Pote, Pote.ColorInfo],
        Converters: [
          Pote.Converters,
          Pote.Converters.RGB,
          Pote.Converters.HSL,
          Pote.Converters.HSV,
          Pote.Converters.CMYK,
          Pote.Converters.XTerm256,
          Pote.Converters.HWB,
          Pote.Converters.Advanced
        ],
        "Color Formats": [
          Pote.Format,
          Pote.Format.RGB,
          Pote.Format.Hex,
          Pote.Format.HSL,
          Pote.Format.HSV,
          Pote.Format.CMYK,
          Pote.Format.ARGB,
          Pote.Format.Atom,
          Pote.Format.ANSI,
          Pote.Format.XTerm256
        ],
        Harmonies: [Pote.Harmonies],
        Gradients: [Pote.Gradients],
        Display: [Pote.Display],
        Validation: [Pote.Validator, Pote.Sanitizer],
        Orchestration: [Pote.Orchestrator],
        Themes: [Pote.Theme, Pote.Theme.Templates]
      ],
      source_ref: @version
    ]
  end

  defp deps do
    [
      {:apero, path: "../apero"},
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      qa: [
        "format",
        "compile",
        "dialyzer",
        "cmd sh -c 'MIX_ENV=test mix test --cover'",
        "cmd sh -c 'alaja json \"$(mix credo --strict --format=json)\"'"
      ]
    ]
  end
end
