# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `Pote.Converters.Advanced.nearest_pantone/1` y `nearest_pantone_name/1` para aproximación de colores Pantone.
- Property-based tests con `stream_data` para verificar roundtrip de conversiones RGB↔Hex, RGB↔HSL, RGB↔HSV.
- Alias `Pote.Converters.RGB` importado en `Pote.Format` para reducir anidamiento.

### Changed
- **Refactor**: `Pote.Conversions` (legacy) ahora delega vía `@deprecated` a `Pote.Converters.*`. Las funciones siguen funcionando pero emiten warning de deprecation.
- `Pote.Converters.Advanced.delta_e/2` es ahora el source-of-truth; `Pote.Conversions.delta_e/2` delega con `@deprecated`.
- `rgb_to_pantone_approx/1` (legacy) ahora delega a `Pote.Converters.Advanced.nearest_pantone/1` con `@deprecated`.

### Deprecated
- `Pote.Conversions.*` está deprecated en favor de `Pote.Converters.*`. Estará en runtime-error en `2.0.0`.

## [1.0.0] - 2026-06-10

### Added
- Initial release: parsing, conversion, harmonization, gradient generation, ANSI rendering across RGB, Hex, HSL, HSV, CMYK, ARGB, XTerm256, Atom.
