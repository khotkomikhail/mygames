defmodule Game.Clan do
  defstruct ~w(name leader_name tag)a

  @type t :: %__MODULE__{name: String.t(), leader_name: String.t(), tag: String.t()}
end
