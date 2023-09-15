defmodule Game.ClanInvitation do
  defstruct ~w(from to clan)a

  @type t :: %__MODULE__{from: String.t(), to: String.t(), clan: String.t()}
end
