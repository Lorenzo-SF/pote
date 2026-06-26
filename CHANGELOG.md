# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-06-27

### Added — `Pote.Theme` heredable theme system
- New macro-generated facade: `use Pote.Theme, config_app: :my_app`
  creates a module like `MyApp.Theme` with `list/0`, `active/0`,
  `activate/1`, `color/1`, `colors/0`, `install!/1`,
  `install_template/1`, `templates/0`, `register_with_pote/0`,
  `storage_dir/0`. Consumer apps (Alaja, Flotilla, etc.) get a
  drop-in facade for theme management that integrates with Pote's
  `theme:<key>` resolver stack.
- New `Pote.Theme.Templates` module with 5 built-in themes (default,
  dracula, monokai, nord, light). Each has the full 22-key colour
  set (primary, secondary, ternary, quaternary, success, warning,
  error, info, debug, happy, sad, gradient_1..6, menu, alert,
  critical, no_color, background).
- `Pote.Theme.save_theme/2` writes JSON in the canonical flat
  `[r,g,b]` format (the format Pote.Theme's resolver expects).
- `Pote.Theme.load_theme/2` reads JSON back into a `Theme` struct.
- `Pote.Theme.resolver/1` builds a resolver function that consults
  `Application.get_env(config_app, :theme_active)` plus a storage
  directory.
- `Pote.put_theme_resolver/1` now stacks resolvers — `Pote.parse`
  walks the stack and returns the first non-`:not_found` result.
  Useful when multiple consumers register their own resolvers
  side-by-side.

## [0.2.0] - 2026-06-24

## [0.2.0] - 2026-06-24

### Added
- **`Pote.Theme`** — new module that exposes a theming system reusable across all Pote-consuming projects. Use it via `use Pote.Theme, config_app: :my_app` to get `list/0`, `active/0`, `activate/1`, `color/1`, `colors/0`, `install!/1`, `install_template/1`, `templates/0`. Themes are JSON files under `~/.config/<app>/themes/`, and the generated module auto-registers its resolver with `Pote` so `theme:<key>` lookups work everywhere.
- **`Pote.Theme.Templates`** — five built-in palettes (`default`, `dracula`, `monokai`, `nord`, `light`) ready to install with `MyApp.Theme.install_template("dracula")`.
- `Pote.Converters.Advanced.nearest_pantone/1` and `nearest_pantone_name/1` for Pantone color approximation.
- Property-based tests using `stream_data` to verify roundtrip of RGB↔Hex, RGB↔HSL, RGB↔HSV conversions.
- `Pote.Converters.RGB` alias imported in `Pote.Format` to reduce nesting.
- `Pote.theme_resolver/0` and `Pote.put_theme_resolver/1` — configurable theme resolver that lets host applications (e.g. Alaja) intercept `theme:<key>` lookups. Falls back to `@default_colors` when the resolver returns `:not_found`.
- `Pote.resolve_theme_color/1` — public API that delegates to the configured theme resolver and falls back to `@default_colors`.

### Fixed
- **BUG**: `Pote.Orchestrator.parse_color("theme:<key>")` and `:key` atom lookup used to ignore the host application's active theme, always returning colors from Pote's hardcoded `@default_colors`. They now consult the configured theme resolver first.
- **BUG**: `Pote.Orchestrator.parse_color/1` accepted a 3-float tuple and silently classified it as HSL or HSV based on the value range. Two identical shapes (`{120.0, 50.0, 50.0}`) could mean either; the heuristic misclassified HSV inputs as HSL. The tuple form now returns `:error` with a message pointing to the unambiguous `hsl:` / `hsv:` string prefix. RGB and CMYK tuples are unaffected.

### Changed
- **i18n**: translated remaining Spanish docstrings and inline comments to English across the library for consistency.
- **Refactor**: `Pote.Conversions` (legacy) now delegates via `@deprecated` to `Pote.Converters.*`. The functions still work but emit a deprecation warning.
- `Pote.Converters.Advanced.delta_e/2` is now the source of truth; `Pote.Conversions.delta_e/2` delegates with `@deprecated`.
- `rgb_to_pantone_approx/1` (legacy) now delegates to `Pote.Converters.Advanced.nearest_pantone/1` with `@deprecated`.

### Deprecated
- `Pote.Conversions.*` is deprecated in favour of `Pote.Converters.*`. It will raise a runtime error in `2.0.0`.

[1.0.0]: https://github.com/Lorenzo-SF/pote/releases/tag/v1.0.0

## [1.0.0] - 2026-06-10

### Added
- Initial open source release: parsing, conversion, harmonization, gradient generation, ANSI rendering across RGB, Hex, HSL, HSV, CMYK, ARGB, XTerm256, Atom.

[1.0.0]: https://hex.pm/packages/pote/1.0.0

[0.2.0]: https://github.com/Lorenzo-SF/pote/releases/tag/v0.2.0
