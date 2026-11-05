defmodule Pote.MixProject do
  use Mix.Project

  @version "3.0.0"

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
        Core: [Pote, Pote.ColorInfo, Pote.Error],
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
          Pote.Format.XTerm256
        ],
        Harmonies: [Pote.Harmonies, Pote.Colors.Basic],
        Gradients: [Pote.Gradients],
        Style: [Pote.Style, Pote.Palette],
        Display: [Pote.Display],
        Validation: [
          Pote.Validator,
          Pote.Validator.Parser,
          Pote.Validator.RGB,
          Pote.Validator.Hex,
          Pote.Validator.HSL,
          Pote.Validator.HSV,
          Pote.Validator.CMYK,
          Pote.Validator.HWB,
          Pote.Validator.Bracket,
          Pote.Validator.XTerm,
          Pote.Validator.Theme,
          Pote.Sanitizer
        ],
        Orchestration: [Pote.Orchestrator, Pote.Orchestrator.Parser],
        Accessibility: [Pote.Accessibility],
        Themes: [Pote.Theme, Pote.Theme.Templates, Pote.Theme.Runtime]
      ],
      source_ref: @version
    ]
  end

  defp deps do
    [
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
      gen: ["clean_build", "deps.get", "compile"],
      clean_build: &clean_build/1,
      qa: [
        "format --check-formatted",
        "compile --warnings-as-errors --force",
        "credo --strict",
        "cmd sh -c 'MIX_ENV=test mix test --cover'",
        "dialyzer"
      ]
    ]
  end

  defp clean_build(_args) do
    File.rm_rf("_build")
    File.rm_rf("deps")
    File.rm_rf("mix.lock")
    Mix.shell().info("✅  Clean slate.")
  end
end
