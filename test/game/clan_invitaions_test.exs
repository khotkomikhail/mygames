defmodule Game.ClanInvitationsTest do
  use ExUnit.Case, async: false

  alias Game.{Clans, Players}
  alias Game.ClanInvitation, as: Invitation

  describe "create invitation" do
    setup do
      assert {:ok, alice} = Players.create(name: "alice")
      assert {:ok, bob} = Players.create(name: "bob")
      assert {:ok, clan} = Clans.create(alice, name: "clan", tag: "[FOO]")

      on_exit(fn ->
        Clans.delete_all()
        Players.delete_all()
      end)

      %{alice: alice, bob: bob, clan: clan}
    end

    test "ok", %{alice: alice, bob: bob, clan: clan} do
      assert {:ok, invitation} = Clans.invite(alice, bob)
      assert invitation.clan == clan.name
      assert invitation.to == bob.name
    end

    test "error: cannot invite myself", %{alice: alice} do
      assert {:error, :not_allowed} = Clans.invite(alice, alice)
    end

    test "error: already in clan", %{alice: alice, bob: bob} do
      assert {:ok, _} = Clans.create(bob, name: "SuperSus", tag: "[SSS]")
      assert {:error, :already_in_clan} = Clans.invite(alice, bob)
    end

    test "error: not in clan", %{bob: bob} do
      assert {:ok, charlie} = Players.create(name: "charlie")
      assert {:error, :not_in_clan} = Clans.invite(bob, charlie)
    end

    test "error: pending invitation", %{alice: alice, bob: bob} do
      assert {:ok, _} = Clans.invite(alice, bob)
      assert {:error, :pending_invitation} = Clans.invite(alice, bob)
    end
  end

  describe "accept invitation" do
    setup do
      assert {:ok, alice} = Players.create(name: "alice")
      assert {:ok, bob} = Players.create(name: "bob")
      assert {:ok, clan} = Clans.create(alice, name: "clan", tag: "[FOO]")
      assert {:ok, invitation} = Clans.invite(alice, bob)

      on_exit(fn ->
        Clans.delete_all()
        Players.delete_all()
      end)

      %{alice: alice, bob: bob, clan: clan, invitation: invitation}
    end

    test "ok", %{bob: bob, invitation: invitation} do
      assert :ok = Clans.accept(bob, invitation)
      assert {:ok, clan} = Clans.whereis(bob)
      assert invitation.clan == clan.name
    end

    test "error: not player's invitation", %{invitation: invitation} do
      assert {:ok, charlie} = Players.create(name: "charlie")
      assert {:error, :not_owner} = Clans.accept(charlie, invitation)
    end

    test "error: already in clan", %{bob: bob, invitation: invitation} do
      assert {:ok, _} = Clans.create(bob, name: "DejaVu", tag: "[DVU]")
      assert {:error, :already_in_clan} = Clans.accept(bob, invitation)
    end

    test "error: no invitation", %{alice: alice, clan: clan} do
      assert {:ok, charlie} = Players.create(name: "charlie")
      invitation = %Invitation{to: charlie.name, clan: clan.name}
      assert {:error, :no_invitation} = Clans.accept(charlie, invitation)
    end
  end

  describe "decline invitation" do
    setup do
      assert {:ok, alice} = Players.create(name: "alice")
      assert {:ok, bob} = Players.create(name: "bob")
      assert {:ok, clan} = Clans.create(alice, name: "clan", tag: "[FOO]")
      assert {:ok, invitation} = Clans.invite(alice, bob)

      on_exit(fn ->
        Clans.delete_all()
        Players.delete_all()
      end)

      %{alice: alice, bob: bob, clan: clan, invitation: invitation}
    end

    test "ok", %{bob: bob, invitation: invitation} do
      assert :ok = Clans.decline(bob, invitation)
      assert {:error, :not_in_clan} = Clans.whereis(bob)
    end

    test "error: not player's invitation", %{invitation: invitation} do
      assert {:ok, charlie} = Players.create(name: "charlie")
      assert {:error, :not_owner} = Clans.accept(charlie, invitation)
    end

    test "error: already in clan", %{bob: bob, invitation: invitation} do
      assert {:ok, _} = Clans.create(bob, name: "DejaVu", tag: "[DVU]")
      assert {:error, :already_in_clan} = Clans.decline(bob, invitation)
    end

    test "error: no invitation", %{alice: alice, clan: clan} do
      assert {:ok, charlie} = Players.create(name: "charlie")
      invitation = %Invitation{to: charlie.name, clan: clan.name}
      assert {:error, :no_invitation} = Clans.decline(charlie, invitation)
    end
  end
end
