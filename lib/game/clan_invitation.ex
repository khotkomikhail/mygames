defmodule Game.ClanInvitation do
  defstruct ~w(to clan)a

  @type t :: %__MODULE__{to: String.t(), clan: String.t()}
end
