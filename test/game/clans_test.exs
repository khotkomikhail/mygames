defmodule Game.ClansTest do
  use ExUnit.Case, async: false

  alias Game.{Clans, Players}

  describe "create clan" do
    setup do
      assert {:ok, alice} = Players.create(name: "alice")
      assert {:ok, bob} = Players.create(name: "bob")

      on_exit(fn ->
        Clans.delete_all()
        Players.delete_all()
      end)

      %{alice: alice, bob: bob}
    end

    test "ok", %{alice: alice} do
      assert {:ok, clan} = Clans.create(alice, name: "clan", tag: "[FOO]")
      assert clan.leader_name == alice.name
      assert clan.name == "clan"
      assert clan.tag == "[FOO]"
    end

    test "error: name already exists", %{alice: alice, bob: bob} do
      assert {:ok, _} = Clans.create(alice, name: "DejaVu", tag: "[DVU]")
      assert {:error, :name_already_exists} = Clans.create(bob, name: "DejaVu", tag: "[DDD]")
    end

    test "error: tag already exists", %{alice: alice, bob: bob} do
      assert {:ok, _} = Clans.create(alice, name: "DejaVu", tag: "[DVU]")
      assert {:error, :tag_already_exists} = Clans.create(bob, name: "DeVaUb", tag: "[DVU]")
    end

    test "error: already in clan", %{alice: alice} do
      assert {:ok, _} = Clans.create(alice, name: "DejaVu", tag: "[DVU]")
      assert {:error, :already_in_clan} = Clans.create(alice, name: "DeVaUb", tag: "[DDD]")
    end
  end
end
