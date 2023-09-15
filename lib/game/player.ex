defmodule Game.Player do
  defstruct ~w(name)a

  @type t :: %__MODULE__{name: String.t()}
end
