# Pote Gallery

Visual guide to Pote's rendering APIs — `Style`, `Gradients`, `Palette`
and `Theme`. Each snippet is runnable in `iex -S mix` and produces
terminal output.

## Style — inline ANSI

```elixir
# Composition: fg |> effect |> bg
Pote.Style.red()
|> Pote.Style.bold()
|> Pote.Style.on("#1e1e2e")
|> Pote.Style.render("hello")
|> IO.iodata_to_binary()
|> IO.puts()
```

Named color helpers are generated for every basic color, and colors
can be atoms, RGB tuples or hex strings:

```elixir
Pote.Style.cyan() |> Pote.Style.underline() |> Pote.Style.render("cyan link")
Pote.Style.fg({255, 128, 0}) |> Pote.Style.render("orange")
Pote.Style.bg("#282c34") |> Pote.Style.render("on background")
```

All seven effects are available: `bold`, `dim`, `italic`, `underline`,
`inverse`, `blink`, `hidden`.

## Gradients — RGB vs perceptual

Plain RGB interpolation produces a muddy middle between saturated
colors:

```elixir
Pote.Gradients.linear({255, 0, 0}, {0, 0, 255}, 5)
# [{255, 0, 0}, {191, 0, 64}, {128, 0, 128}, {64, 0, 191}, {0, 0, 255}]
```

Perceptual spaces (OKLCH, LAB) keep the transition vivid and even:

```elixir
Pote.Gradients.linear_oklch({255, 0, 0}, {0, 0, 255}, 5)
# [{255, 0, 0}, {232, 0, 123}, {186, 0, 194}, {122, 0, 244}, {0, 0, 255}]

Pote.Gradients.linear_lab({255, 0, 0}, {0, 0, 255}, 5)
```

Colorize text directly:

```elixir
"gradient text"
|> Pote.Gradients.apply_to_text({255, 0, 0}, {0, 0, 255})
|> IO.iodata_to_binary()
|> IO.puts()
```

## Palette — procedural generation

Deterministic palettes from a seed, optionally WCAG AA compliant
(luminance ladder between consecutive colors):

```elixir
Pote.Palette.generate(42, count: 5, wcag_aa: true)
|> Enum.each(fn {r, g, b} ->
  IO.puts(IO.ANSI.format([:reset, "\e[48;2;#{r};#{g};#{b}m     "]))
end)
```

Bases: `:harmonious` (triad, default), `:analogous`, `:complementary`.

## Theme — named palettes

```elixir
Pote.Theme.load_json(~s({"name":"my","colors":{"primary":[161,231,250]}}))

# Built-in templates
Pote.Theme.Templates.names()
# ["default", "dracula", "monokai", "nord", "light"]

Pote.Theme.Templates.fetch("dracula")
```

## Accessibility — check before you ship

Simulate how color-blind users see your palette:

```elixir
Pote.Accessibility.simulate({255, 0, 0}, :protanopia)
Pote.Accessibility.simulate({0, 255, 0}, :deuteranopia)
Pote.Accessibility.simulate({0, 0, 255}, :tritanopia)

Pote.Accessibility.distinguishable?({255, 0, 0}, {0, 255, 0}, :deuteranopia)
```

## Contrast — WCAG ratios

```elixir
Pote.Converters.Advanced.contrast_ratio({205, 214, 244}, {30, 30, 46})
# 11.34 — passes AAA for normal text
```
