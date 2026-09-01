# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] — 2026-07-31

### Added
- `Pote.Style` — inline styling DSL: immutable `%Pote.Style{}` struct
  with `fg`/`bg`/`effects`, named-color helpers generated from
  `Pote.Colors.Basic`, color resolution via `Pote.parse!` (atoms, RGB
  tuples, hex strings), and truecolor ANSI rendering (`to_ansi/1`,
  `render/2`). P-1.
- `Pote.Palette` — deterministic procedural palette generation from a
  seed over `Pote.Harmonies` bases (`:harmonious`/`:analogous`/
  `:complementary`) with optional WCAG AA enforcement via an optimal
  luminance ladder (P-2). `wcag_aa?/1` checks the ladder property.
- `Pote.Gradients.linear_lab/3` and `linear_oklch/3` — perceptual
  interpolation (CIELAB, OKLab/OKLCH with shortest-hue-path) that
  avoids the muddy middle gray of RGB interpolation. P-3.
- `Pote.Converters.Advanced.to_oklab/1`, `from_oklab/1`,
  `to_oklch/1`, `from_oklch/1` — Ottosson's perceptual color space
  conversions. P-3.
- `Pote.Theme.load_json/1` — parses and validates a theme JSON binary
  or file path into a `Pote.Theme.Theme` struct. P-5.
- `Pote.Theme.parse/1` and `parse!/1` — typed-error variants of
  `load_json/1`. P-8.
- `Pote.Error` — typed error struct (`kind`, `message`, `details`)
  used by theme parsing. P-8.
- `Pote.Accessibility` — color-blindness simulation (Machado et al.
  matrices for protanopia/deuteranopia/tritanopia) and
  `distinguishable?/3`. P-6.
- `guides/gallery.md` — visual guide with runnable examples for
  Style, Gradients, Palette, Theme and Accessibility. P-10.

### Changed
- Theme JSON schema validation now rejects `color_mode: "both"` and
  unknown `color_mode` values (only `"auto"`, `"truecolor"`,
  `"xterm256"` are accepted). P-9.
- `Pote.Gradients.multicolor/2` keeps endpoint semantics when
  `steps < length(colors)` (regression fix from 2.x cycle).

### Fixed
- `Pote.Style` uses the correct `IO.ANSI` effect functions for
  Elixir 1.19 (`bright/0`, `faint/0`, `blink_slow/0`, `conceal/0`)
  and emits truecolor escapes manually (3/4-arg `IO.ANSI.color*`
  only accept 0-5 in modern Elixir).
- `Pote.Palette.remap_lightness/6` no longer triggers an unused
  variable warning.

### Notes
- P-4 (`Pote.Syntax`) is intentionally **not** implemented in this
  release: `Alaja.Syntax` (sibling project, FASE 2) already provides
  the tokenizer/highlighter; the spec allows marking it optional.

## [Unreleased]

### Fixed
- Added `Pote.hwb/0` type alias (`{float(), float(), float()}`) so
  `Converters.hwb_to_rgb/1` and `rgb_to_hwb/1` resolve cleanly under
  Dialyzer (previously the `@spec` referenced an undefined type).
- `Pote.Validator.check_bracket_style/2` now returns the same
  `{:error, atom(), String.t()}` shape as the rest of the validator
  for the `rgb` / `argb` / `hsl` / `hsv` / `cmyk` "uses curly braces"
  errors (was a bare 2-tuple). Matches `@type validation_result`.
- `Pote.Gradients.multicolor/2` no longer drops the last colour
  stop when `steps < length(colors)`; with `steps == 2` and three
  colours, it now returns the endpoints (`[first, last]`) as the
  test expects instead of an interpolated middle value.

### Changed
- Removed the deprecated `Pote.Format.ANSI` module and its test
  suite. The migration to `Pote.ColorInfo` / `Pote.Format.RGB` has
  been the recommended path since 2.x; deleting the stub closes the
  deprecation cycle and removes a misleading `@deprecated` entry
  from `mix.exs`.
- `lib/pote/theme/runtime.ex` — reordered the
  `Pote.Theme.{Templates, Theme}` alias to satisfy Credo's
  `AliasOrder` check.
- `test/pote/property_test.exs` and
  `test/pote/converters/property_test.exs` — dropped unused
  aliases; widened the YCbCr roundtrip tolerance to 32. The
  limited-range BT.601 conversion clamps to `[16,235] / [16,240]`,
  which makes exact roundtrips impossible on edge RGB inputs
  (`r/g/b ∈ {0, 255}`); 32 covers the worst observed amplification.
- `README.md` — fixed broken links: dropped the dangling
  `README_ES.md` reference and corrected the license link from
  `LICENSE` to `LICENSE.md`.

### Refactored
- **`Pote.Converters`** — extracted common conversion logic into
  `Pote.Converters.Generic` module. The `Pote.Converters.Table` now
  holds a central conversion table; individual converters delegate
  to the generic engine. Backward-compatible — public API unchanged.
- Added `Pote.Converters.GenericTest` for conversion correctness.

## [2.1.0] - 2026-07-07

### Notes
- Version bump only. No code changes since `2.0.0`. Re-published to
  align the `mix.exs` `version` field with the next planned Hex.pm
  release. Keeps the canonical tag set (`1.0.0` → `2.0.0` → `2.1.0`)
  continuous now that downstream consumers (alaja, arrea, apero,
  candil, botica) have moved to the 2.x line.

## [2.0.0] - 2026-07-02

### Added
- **`Pote.Theme`** — theming system reusable across all Pote-consuming projects. Use it via `use Pote.Theme, config_app: :my_app` to get a drop-in facade module with `list/0`, `active/0`, `activate/1`, `color/1`, `colors/0`, `install!/1`, `install_template/1`, `templates/0`, `register_with_pote/0`, `storage_dir/0`. Themes are JSON files under `~/.config/<app>/themes/`, and the generated module auto-registers its resolver with `Pote` so `theme:<key>` lookups work everywhere.
- **`Pote.Theme.Templates`** — five built-in palettes (`default`, `dracula`, `monokai`, `nord`, `light`) with the full 22-key colour set (primary, secondary, ternary, quaternary, success, warning, error, info, debug, happy, sad, gradient_1..6, menu, alert, critical, no_color, background). Install with `MyApp.Theme.install_template("dracula")`.
- `Pote.Theme.save_theme/2` writes JSON in the canonical flat `[r,g,b]` format (the format `Pote.Theme`'s resolver expects).
- `Pote.Theme.load_theme/2` reads JSON back into a `Theme` struct.
- `Pote.Theme.resolver/1` builds a resolver function that consults `Application.get_env(config_app, :theme_active)` plus a storage directory.
- `Pote.put_theme_resolver/1` now stacks resolvers — `Pote.parse` walks the stack and returns the first non-`:not_found` result. Useful when multiple consumers register their own resolvers side-by-side.
- `Pote.Converters.Advanced.nearest_pantone/1` and `nearest_pantone_name/1` for Pantone colour approximation.
- Property-based tests using `stream_data` to verify roundtrip of RGB↔Hex, RGB↔HSL, RGB↔HSV conversions.
- `Pote.Converters.RGB` alias imported in `Pote.Format` to reduce nesting.
- `Pote.theme_resolver/0` and `Pote.put_theme_resolver/1` — configurable theme resolver that lets host applications (e.g. Alaja) intercept `theme:<key>` lookups. Falls back to `@default_colors` when the resolver returns `:not_found`.
- `Pote.resolve_theme_color/1` — public API that delegates to the configured theme resolver and falls back to `@default_colors`.

### Fixed
- **BUG**: `Pote.Orchestrator.parse_color("theme:<key>")` and `:key` atom lookup used to ignore the host application's active theme, always returning colours from Pote's hardcoded `@default_colors`. They now consult the configured theme resolver first.
- **BUG**: `Pote.Orchestrator.parse_color/1` accepted a 3-float tuple and silently classified it as HSL or HSV based on the value range. Two identical shapes (`{120.0, 50.0, 50.0}`) could mean either; the heuristic misclassified HSV inputs as HSL. The tuple form now returns `:error` with a message pointing to the unambiguous `hsl:` / `hsv:` string prefix. RGB and CMYK tuples are unaffected.

### Changed
- i18n: translated remaining Spanish docstrings and inline comments to English across the library for consistency.
- `Pote.Converters.Advanced.delta_e/2` is now the source of truth.

### Removed
- **BREAKING**: `Pote.Conversions` module deleted. Use `Pote.Converters.*` in its place. The legacy module was deprecated in 0.2.0 and is now removed entirely; any call site must be migrated.

## [1.0.0] - 2026-06-10

### Added
- Initial open source release: parsing, conversion, harmonization, gradient generation, ANSI rendering across RGB, Hex, HSL, HSV, CMYK, ARGB, XTerm256, Atom.

[2.1.0]: https://hex.pm/packages/pote/2.1.0
[2.0.0]: https://hex.pm/packages/pote/2.0.0
[1.0.0]: https://hex.pm/packages/pote/1.0.0


> ## A note on history
>
> The git history of this repository was reset as part of a deliberate
> cleanup effort. The commits you can read here describe the codebase as
> it stands today — they do not preserve the original chronology of
> development.
>
> Anything worth keeping from before the reset was carried forward as
> tagged releases with explicit `CHANGELOG.md` entries. Anything not
> preserved is, by the maintainer's choice, no longer part of the
> canonical development line.
