defmodule Game.PlayersTest do
  use ExUnit.Case, async: false

  alias Game.Players

  describe "create player" do
    setup do
      on_exit(fn ->
        Players.delete_all()
      end)
    end

    test "ok" do
      assert {:ok, player} = Players.create(name: "player")
      assert player.name == "player"
    end

    test "error: name already exists" do
      assert {:ok, _} = Players.create(name: "player")
      assert {:error, :name_already_exists} = Players.create(name: "player")
    end
  end
end
