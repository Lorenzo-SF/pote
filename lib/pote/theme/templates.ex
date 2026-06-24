defmodule Pote.Theme.Templates do
  @moduledoc """
  Built-in theme templates that ship with Pote.

  Consumers can install any of these via
  `MyApp.Theme.install_template("dracula")` (where `MyApp.Theme` is
  the module built with `use Pote.Theme`).

  Adding a new template is a one-liner: add an entry to
  `@templates` and it becomes available everywhere.
  """

  @default %Pote.Theme.Theme{
    name: "default",
    description: "Default Pote palette — bright on dark",
    colors: %{
      "primary" => {161, 231, 250},
      "secondary" => {58, 171, 163},
      "ternary" => {255, 128, 0},
      "quaternary" => {155, 66, 226},
      "no_color" => {248, 248, 242},
      "background" => {40, 44, 52},
      "success" => {151, 197, 60},
      "warning" => {253, 216, 8},
      "error" => {255, 91, 91},
      "info" => {0, 255, 255},
      "menu" => {171, 205, 241},
      "alert" => {253, 216, 8},
      "critical" => {255, 91, 91},
      "debug" => {176, 176, 176},
      "happy" => {238, 128, 195},
      "sad" => {129, 161, 193},
      "gradient_1" => {161, 231, 250},
      "gradient_2" => {136, 192, 208},
      "gradient_3" => {129, 161, 193},
      "gradient_4" => {94, 129, 172},
      "gradient_5" => {76, 86, 106},
      "gradient_6" => {67, 76, 94}
    }
  }

  @dracula %Pote.Theme.Theme{
    name: "dracula",
    description: "Dracula colour palette",
    colors: %{
      "primary" => {189, 147, 249},
      "secondary" => {68, 71, 90},
      "ternary" => {255, 184, 108},
      "quaternary" => {255, 121, 198},
      "no_color" => {248, 248, 242},
      "background" => {40, 42, 54},
      "success" => {80, 250, 123},
      "warning" => {241, 250, 140},
      "error" => {255, 85, 85},
      "info" => {139, 233, 253},
      "menu" => {98, 114, 164},
      "alert" => {255, 184, 108},
      "critical" => {255, 85, 85},
      "debug" => {98, 114, 164},
      "happy" => {255, 121, 198},
      "sad" => {98, 114, 164},
      "gradient_1" => {255, 121, 198},
      "gradient_2" => {189, 147, 249},
      "gradient_3" => {139, 233, 253},
      "gradient_4" => {80, 250, 123},
      "gradient_5" => {241, 250, 140},
      "gradient_6" => {255, 184, 108}
    }
  }

  @monokai %Pote.Theme.Theme{
    name: "monokai",
    description: "Monokai colour palette",
    colors: %{
      "primary" => {166, 226, 46},
      "secondary" => {102, 217, 239},
      "ternary" => {253, 151, 31},
      "quaternary" => {174, 129, 255},
      "no_color" => {248, 248, 242},
      "background" => {39, 40, 34},
      "success" => {166, 226, 46},
      "warning" => {230, 219, 116},
      "error" => {249, 38, 114},
      "info" => {102, 217, 239},
      "menu" => {117, 113, 94},
      "alert" => {253, 151, 31},
      "critical" => {249, 38, 114},
      "debug" => {117, 113, 94},
      "happy" => {174, 129, 255},
      "sad" => {117, 113, 94},
      "gradient_1" => {166, 226, 46},
      "gradient_2" => {230, 219, 116},
      "gradient_3" => {253, 151, 31},
      "gradient_4" => {249, 38, 114},
      "gradient_5" => {174, 129, 255},
      "gradient_6" => {102, 217, 239}
    }
  }

  @nord %Pote.Theme.Theme{
    name: "nord",
    description: "Nord colour palette — arctic, north-bluish",
    colors: %{
      "primary" => {136, 192, 218},
      "secondary" => {129, 161, 193},
      "ternary" => {235, 203, 139},
      "quaternary" => {180, 142, 173},
      "no_color" => {236, 239, 244},
      "background" => {46, 52, 64},
      "success" => {163, 190, 140},
      "warning" => {235, 203, 139},
      "error" => {191, 97, 106},
      "info" => {129, 161, 193},
      "menu" => {76, 86, 106},
      "alert" => {208, 135, 112},
      "critical" => {191, 97, 106},
      "debug" => {76, 86, 106},
      "happy" => {180, 142, 173},
      "sad" => {76, 86, 106},
      "gradient_1" => {136, 192, 218},
      "gradient_2" => {163, 190, 140},
      "gradient_3" => {235, 203, 139},
      "gradient_4" => {208, 135, 112},
      "gradient_5" => {191, 97, 106},
      "gradient_6" => {180, 142, 173}
    }
  }

  @light %Pote.Theme.Theme{
    name: "light",
    description: "Light palette — dark on light",
    colors: %{
      "primary" => {0, 120, 215},
      "secondary" => {0, 150, 136},
      "ternary" => {255, 110, 64},
      "quaternary" => {124, 77, 255},
      "no_color" => {40, 44, 52},
      "background" => {250, 250, 252},
      "success" => {60, 165, 70},
      "warning" => {255, 175, 0},
      "error" => {220, 50, 50},
      "info" => {0, 145, 215},
      "menu" => {100, 110, 130},
      "alert" => {255, 175, 0},
      "critical" => {220, 50, 50},
      "debug" => {140, 140, 140},
      "happy" => {220, 100, 170},
      "sad" => {110, 130, 160},
      "gradient_1" => {0, 120, 215},
      "gradient_2" => {60, 165, 70},
      "gradient_3" => {255, 175, 0},
      "gradient_4" => {255, 110, 64},
      "gradient_5" => {124, 77, 255},
      "gradient_6" => {100, 110, 130}
    }
  }

  @templates %{@default.name => @default, @dracula.name => @dracula, @monokai.name => @monokai,
               @nord.name => @nord, @light.name => @light}

  @doc "Returns the list of built-in template theme names."
  @spec names() :: [String.t()]
  def names, do: Map.keys(@templates)

  @doc "Looks up a built-in template by name."
  @spec fetch(String.t()) :: {:ok, Pote.Theme.Theme.t()} | :error
  def fetch(name) when is_binary(name) do
    case Map.fetch(@templates, name) do
      {:ok, _} = ok -> ok
      :error -> :error
    end
  end

  @doc "Returns all built-in templates."
  @spec all() :: %{optional(String.t()) => Pote.Theme.Theme.t()}
  def all, do: @templates
end