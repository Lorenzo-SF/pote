# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `Pote.Converters.Advanced.nearest_pantone/1` and `nearest_pantone_name/1` for Pantone color approximation.
- Property-based tests using `stream_data` to verify roundtrip of RGB↔Hex, RGB↔HSL, RGB↔HSV conversions.
- `Pote.Converters.RGB` alias imported in `Pote.Format` to reduce nesting.

### Changed
- **i18n**: translated remaining Spanish docstrings and inline comments to English across the library for consistency.
- **Refactor**: `Pote.Conversions` (legacy) now delegates via `@deprecated` to `Pote.Converters.*`. The functions still work but emit a deprecation warning.
- `Pote.Converters.Advanced.delta_e/2` is now the source of truth; `Pote.Conversions.delta_e/2` delegates with `@deprecated`.
- `rgb_to_pantone_approx/1` (legacy) now delegates to `Pote.Converters.Advanced.nearest_pantone/1` with `@deprecated`.

### Deprecated
- `Pote.Conversions.*` is deprecated in favour of `Pote.Converters.*`. It will raise a runtime error in `2.0.0`.

## [1.0.0] - 2026-06-10

### Added
- Initial open source release: parsing, conversion, harmonization, gradient generation, ANSI rendering across RGB, Hex, HSL, HSV, CMYK, ARGB, XTerm256, Atom.

[1.0.0]: https://hex.pm/packages/pote/1.0.0
