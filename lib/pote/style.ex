defmodule Pote.Style do
  @moduledoc """
  Inline styling DSL — compose foreground, background and text effects
  into an immutable `%Pote.Style{}` struct, then render text with ANSI
  escapes.

  `Pote.Style` is the agnostic, terminal-agnostic layer: it resolves
  colors (atoms from `Pote.Colors.Basic`, RGB tuples, hex strings via
  `Pote.parse/1`) and emits truecolor ANSI. Deciding whether to fall
  back to 256-color or no-color modes is the host's job (alaja does this
  for the TUI).

  ## Example

      iex> style = Pote.Style.red() |> Pote.Style.bold() |> Pote.Style.on("#1e1e2e")
      iex> style.fg
      {255, 0, 0}
      iex> style.bg
      {30, 30, 46}
      iex> style.effects
      [:bold]
      iex> Pote.Style.render(style, "hi") |> IO.iodata_to_binary()
      "\e[1m\e[38;2;255;0;0m\e[48;2;30;30;46mhi\e[0m"
  """

  @type effect :: :bold | :dim | :italic | :underline | :inverse | :blink | :hidden

  @type t :: %__MODULE__{
          fg: Pote.rgb() | nil,
          bg: Pote.rgb() | nil,
          effects: [effect()]
        }

  defstruct fg: nil, bg: nil, effects: []

  @type color_input :: atom() | binary() | Pote.rgb()

  # -- effects ------------------------------------------------------------

  for effect <- [:bold, :dim, :italic, :underline, :inverse, :blink, :hidden] do
    @doc """
    Adds the `#{effect}` effect to the style.

    ## Examples

        iex> Pote.Style.bold().effects
        [:bold]
    """
    @spec unquote(effect)(t()) :: t()
    def unquote(effect)(style \\ %__MODULE__{}) do
      add_effect(style, unquote(effect))
    end
  end

  # -- named colors -------------------------------------------------------

  for {name, _rgb} <- Pote.Colors.Basic.named_colors() do
    @doc """
    Returns a style with `#{name}` as the foreground color.

    ## Examples

        iex> Pote.Style.red().fg
        {255, 0, 0}
    """
    @spec unquote(name)(t()) :: t()
    def unquote(name)(style \\ %__MODULE__{}) do
      fg(style, unquote(name))
    end
  end

  # -- fg / bg / on -------------------------------------------------------

  @doc """
  Sets the foreground color on a style.

  Accepts a color name atom (`:red`), an RGB tuple, or a hex string
  (`"#ff0000"`).

  ## Examples

      iex> Pote.Style.new() |> Pote.Style.fg(:red)
      %Pote.Style{fg: {255, 0, 0}, bg: nil, effects: []}
  """
  @spec fg(t(), color_input()) :: t()
  def fg(style \\ %__MODULE__{}, color) do
    %{style | fg: resolve(color)}
  end

  @doc """
  Sets the background color on a style. Alias of `on/2`.

  ## Examples

      iex> Pote.Style.new() |> Pote.Style.bg("#1e1e2e")
      %Pote.Style{fg: nil, bg: {30, 30, 46}, effects: []}
  """
  @spec bg(t(), color_input()) :: t()
  def bg(style \\ %__MODULE__{}, color) do
    %{style | bg: resolve(color)}
  end

  @doc """
  Sets the background color on a style (terminal-idiomatic "on").

  ## Examples

      iex> Pote.Style.red() |> Pote.Style.on(:black)
      %Pote.Style{fg: {255, 0, 0}, bg: {0, 0, 0}, effects: []}
  """
  @spec on(t(), color_input()) :: t()
  def on(style \\ %__MODULE__{}, color) do
    bg(style, color)
  end

  # -- rendering ----------------------------------------------------------

  @doc """
  Returns an empty style (no fg, no bg, no effects).

  ## Examples

      iex> Pote.Style.new()
      %Pote.Style{fg: nil, bg: nil, effects: []}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Returns the ANSI escape sequence for the style as iodata.

  The result is a binary suitable to be prepended to text; it does not
  include the reset sequence (use `render/2` for that).

  ## Examples

      iex> Pote.Style.red() |> Pote.Style.to_ansi()
      "\e[38;2;255;0;0m"
  """
  @spec to_ansi(t()) :: IO.iodata()
  def to_ansi(%__MODULE__{} = style) do
    [
      Enum.map(style.effects, &effect_ansi/1),
      fg_ansi(style.fg),
      bg_ansi(style.bg)
    ]
  end

  @doc """
  Renders `text` with the style applied, including the reset sequence.

  ## Examples

      iex> Pote.Style.red() |> Pote.Style.render("hi") |> IO.iodata_to_binary()
      "\e[38;2;255;0;0mhi\e[0m"
  """
  @spec render(t(), binary()) :: IO.iodata()
  def render(%__MODULE__{} = style, text) do
    [to_ansi(style), text, IO.ANSI.reset()]
  end

  # -- private ------------------------------------------------------------

  defp add_effect(%__MODULE__{effects: effects} = style, effect) do
    %{style | effects: Enum.uniq(effects ++ [effect])}
  end

  defp resolve({r, g, b} = rgb) when is_integer(r) and is_integer(g) and is_integer(b),
    do: rgb

  defp resolve(color) when is_atom(color) or is_binary(color), do: Pote.parse!(color)

  defp fg_ansi(nil), do: []
  defp fg_ansi({r, g, b}), do: "\e[38;2;#{r};#{g};#{b}m"

  defp bg_ansi(nil), do: []
  defp bg_ansi({r, g, b}), do: "\e[48;2;#{r};#{g};#{b}m"

  defp effect_ansi(:bold), do: IO.ANSI.bright()
  defp effect_ansi(:dim), do: IO.ANSI.faint()
  defp effect_ansi(:italic), do: IO.ANSI.italic()
  defp effect_ansi(:underline), do: IO.ANSI.underline()
  defp effect_ansi(:inverse), do: IO.ANSI.inverse()
  defp effect_ansi(:blink), do: IO.ANSI.blink_slow()
  defp effect_ansi(:hidden), do: IO.ANSI.conceal()
end
