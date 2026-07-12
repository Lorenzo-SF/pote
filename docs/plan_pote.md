# Plan for `@pote` (Colorimetry and Theme Library)

> **Goal:** Refactor the color conversion primitives to a single generic
> module (`Pote.Converters.Generic`) and eliminate duplicate logic across
> separate converters (`RGB`, `HSL`, `HSV`, etc.).  In addition, tighten
> the test coverage to 100 % for all conversion modules, enrich the
> documentation, and verify the **style/quality** workflow.
>
> The plan is split into the following high‑level phases:
>
> 1. **Preparation** – Verify branch, ensure clean workspace, update
>    dependency paths.
> 2. **Implementation** – Code changes, refactor, add helper logic.
> 3. **Testing** – Add new unit tests, run `mix test --cover`.
> 4. **Documentation** – Update the README, docs, and generated
>    changelog.
> 5. **Quality** – Format, compile, credo, and dialyzer.
> 6. **Commit & Push** – Record the work in a single commit.
>
> Each section contains **action items** that can be tackled in a single
> `mix` session or a handful of editor steps.

## 1. Preparation

| Step | Action | Outcome |
|------|--------|---------|
| 1.1 | Switch to branch `fix-tools-domains` | Ready to work
| 1.2 | Ensure the working tree is clean (commit any in‑progress changes before starting) | Workspace clean
| 1.3 | `mix deps.get` & `mix deps.compile` | Ensure local deps are fetched
| 1.4 | Verify dependency overrides in `pote/mix.exs`
| 1.5 | Commit any outstanding changes in all peers **before starting** (e.g., `pote/mix.exs` with the path override)

> ***Why?***
> - Dependency overrides are essential for fast local iteration.
> - Keeping the workspace pristine avoids merge conflicts when the
>   plan is executed step‑by‑step.

## 2. Implementation

| Module | Change | Reason | Implementation Notes |
|--------|--------|--------|----------------------|
| `Pote.Converters` | Create a **Generic converter** that accepts a conversion table (from/to enums + transform funs). | Remove 15+ duplicated functions across RGB, HSL, HSV, ... | • The table maps each conversion to a `{:ok, fun}`. |
| `Pote.Converters.{RGB, HSL, HSV, CMYK, XTerm256, HWB, Advanced}` | Replace specific implementation with calls to the Generic module. | Uniform API, easier maintenance | • Keep the old public interface for backward compatibility by delegating to Generic.
| `mix.exs` | Add a new mix alias `qa: ["format", "compile", "dialyzer", "credo --strict", "test --cover"]` if not present. | Quick quality workflow | • Will be used in the quality phase.
| `test/pote/` | No code changes here yet. | Placeholder for new tests | • Tests for Generic conversions will be added.

### Key Implementation Snippets

**Generic Converter (`lib/pote/converters/generic.ex`):**
```elixir
defmodule Pote.Converters.Generic do
  @moduledoc """
  General‑purpose color conversion engine.
  `convert/3` takes `from/1`, `to/1` and an input map
  `%{color: struct, format: atom} -> {:ok, %{color: struct, format: atom}}
  """

  @spec convert(Pote.ColorInfo.t(), Pote.ColorInfo.t(), map()) :: {:ok, map()}
  def convert(%{format: from}, %{format: to} = input, table) when from != to do
    case Map.fetch(table, {from, to}) do
      {:ok, fun} -> {:ok, fun.(input)}
      :error -> {:error, :unsupported}
    end
  end
  def convert(_, input, _), do: {:ok, input}
end
```

**Sample Table (extracted from the old converters):**
```elixir
@conversion_table {
  {:rgb, :hsl} => fn %{color: %{r: r, g: g, b: b}} -> # convert RGB → HSL
  { :hsl, :rgb } => fn %{color: %{h: h, s: s, l: l}} -> # HSL → RGB
  ...
}
```

> All existing converter modules will simply call to
> `Pote.Converters.Generic.convert/3` with the appropriate conversion
> table.

## 3. Testing

Create new test module:

**`test/pote/converters/generic_test.exs`**
```elixir
defmodule Pote.Converters.GenericTest do
  use ExUnit.Case
  doctest Pote.Converters.Generic

  alias Pote.Converters.Generic

  @conversion_table Pote.Converters.Table.get()

  @tag :skip
  test "RGB → HSL conversion correctness" do
    rgb = %{format: :rgb, color: %{r: 255, g: 0, b: 0}}
    assert {:ok, %{:color => %{h: _, s: _, l: _}}} = Generic.convert(rgb, %{format: :hsl}, @conversion_table)
  end
end
```

Run:
```bash
mix test --cover
```
- Aim for **100 % coverage** on all converter modules.
- Use `:excoveralls` plugin to generate the report.
- Add *property* tests (cabal `StreamData`) to verify color round‑trip.

## 4. Documentation

| File | Update |
|------|--------|
| `README.md` | Add a section about the Generic converter and its benefits.
| `docs/README.es.md` | Mirror the changes in Spanish.
| `CHANGELOG.md` | Add an entry `## 2.4.0 – refactored color converters`.
| `mix.exs` | Ensure `docs: docs/` include new file.

### Suggested Markdown Snippet
```md
### New Generic Converter
The `Pote.Converters.Generic` module replaces the old `A`, `B`, ...
converter modules.  It focuses on a **single entry point**:

```elixir
{:ok, result} = Pote.Converters.Generic.convert(from_color, to_color, Pote.Converters.Table.get())
```
This change improves testability and maintenance.
```
```

## 5. Quality

Run the full pipeline for the project:
```bash
cd <project-root>
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict --format=json
mix test --cover
mix dialyzer
```
- No warnings or errors should surface.  If any appear, fix them immediately.
- Record the elapsed time to gauge regression.

## 6. Commit & Push

```bash
git add -A
git commit -m "Refactor color converters → Generic module; add tests & docs"
git push origin fix-tools-domains
```

---

**End of plan for `@pote`**

Feel free to proceed through each section step‑by‑step.  Let me know once you reach a point where you need concrete code changes or further instructions.
