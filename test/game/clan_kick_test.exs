defmodule Game.ClanKickTest do
  use ExUnit.Case, async: false

  alias Game.{Clans, Players}

  decribe "kick from clan" do
    setup do
      assert {:ok, alice} = Players.create(name: "alice")
      assert {:ok, bob} = Players.create(name: "bob")
      assert {:ok, clan} = Clans.create(alice, name: "clan", tag: "[FOO]")
      assert {:ok, invitation} = Clans.invite(alice, bob)
      assert :ok = Clans.accept(bob, invitation)

      on_exit(fn ->
        Clans.delete_all()
        Players.delete_all()
      end)

      %{alice: alice, bob: bob, clan: clan}
    end

    test "ok", %{alice: alice, bob: bob} do
      assert :ok = Clans.kick(alice, bob)
      assert {:error, :not_in_clan} = Clans.whereis(bob)
    end

    test "error: cannot kick myself", %{alice: alice} do
      assert {:error, :not_allowed} = Clans.kick(alice, alice)
    end

    test "error: not a leader", %{alice: alice, bob: bob} do
      assert {:error, :not_leader} = Clans.kick(bob, alice)
    end

    test "error: not a member", %{alice: alice} do
      {:ok, charlie} = Players.create(name: "charlie")
      assert {:error, :not_member} = Clans.kick(alice, charlie)
    end
  end
end
