defmodule Game.Clans do
  alias Game.{Clan, Player}
  alias Game.ClanInvitation, as: Invitation

  use GenServer

  @type opt :: {:name, String.t()} | {:tag, String.t()}
  @type opts :: [opt()]
  @type create_error :: :name_already_exists | :tag_already_exists | :already_in_clan
  @type invite_error :: :already_in_clan | :not_allowed | :not_in_clan | :pending_invitation
  @type accept_error :: :not_owner | :already_in_clan | :no_invitation
  @type decline_error :: :not_owner | :already_in_clan | :no_invitation
  @type kick_error :: :not_allowed | :not_leader | :not_in_clan

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec create(Player.t(), opts()) :: {:ok, Clan.t()} | {:error, create_error()}
  def create(player, opts) do
    clan = %Clan{
      name: Keyword.fetch!(opts, :name),
      tag: Keyword.fetch!(opts, :tag),
      leader_name: player.name
    }

    GenServer.call(__MODULE__, {:create, clan})
  end

  @spec invite(Player.t(), Player.t()) :: {:ok, Invitation.t()} | {:error, invite_error()}
  def invite(from, from), do: {:error, :not_allowed}

  def invite(from, to) do
    GenServer.call(__MODULE__, {:invite, from.name, to.name})
  end

  @spec accept(Player.t(), Invitation.t()) :: :ok | {:error, accept_error()}
  def accept(player, invitation) when player.name != invitation.to, do: {:error, :not_owner}

  def accept(_player, invitation) do
    GenServer.call(__MODULE__, {:accept, invitation})
  end

  @spec decline(Player.t(), Invitation.t()) :: :ok | {:error, decline_error()}
  def decline(player, invitation) when player.name != invitation.to, do: {:error, :not_owner}

  def decline(_player, invitation) do
    GenServer.call(__MODULE__, {:decline, invitation})
  end

  @spec kick(Player.t(), Player.t()) :: :ok | {:error, kick_error()}
  def kick(player, player), do: {:error, :not_allowed}

  def kick(leader, player) do
    GenServer.call(__MODULE__, {:kick, leader.name, player.name})
  end

  @spec whereis(Player.t()) :: {:ok, Clan.t()} | {:error, :not_in_clan}
  def whereis(player) do
    GenServer.call(__MODULE__, {:whereis, player.name})
  end

  @spec delete_all :: :ok
  def delete_all do
    GenServer.call(__MODULE__, :delete_all)
  end

  @impl GenServer
  def init(nil) do
    {:ok, %{clans: %{}, members: %{}, tags: %{}, invitations: %{}}}
  end

  @impl GenServer
  def handle_call({:create, clan}, _from, state) do
    case do_create(clan, state) do
      {:ok, new_state} ->
        {:reply, {:ok, clan}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:invite, from, to}, _from, state) do
    case do_invite(from, to, state) do
      {:ok, invitation, new_state} ->
        {:reply, {:ok, invitation}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:accept, invitation}, _from, state) do
    case do_accept(invitation, state) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:decline, invitation}, _from, state) do
    case do_decline(invitation, state) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:kick, leader, player}, _from, state) do
    case do_kick(leader, player, state) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:whereis, player_name}, _from, state) do
    case do_find_clan(player_name, state) do
      {:ok, clan} ->
        {:reply, {:ok, clan}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:delete_all, _from, _state) do
    {:reply, :ok, %{clans: %{}, members: %{}, tags: %{}, invitations: %{}}}
  end

  defp do_create(clan, %{clans: clans, tags: tags, members: members, invitations: invitations} = state) do
    cond do
      Map.has_key?(clans, clan.name) ->
        {:error, :name_already_exists}

      Map.has_key?(tags, clan.tag) ->
        {:error, :tag_already_exists}

      Map.has_key?(members, clan.leader_name) ->
        {:error, :already_in_clan}

      true ->
        {:ok,
         %{
           state
           | clans: Map.put(clans, clan.name, clan),
             tags: Map.put(tags, clan.tag, clan.name),
             members: Map.put(members, clan.leader_name, {clan.name, true}),
             invitations: Map.delete(invitations, clan.leader_name)
         }}
    end
  end

  defp do_invite(from, to, %{members: members, invitations: invitations} = state) do
    {clan, _is_leader} = Map.get(members, from, {nil, nil})
    {current_clan, _is_leader} = Map.get(members, to, {nil, nil})
    player_invitations = Map.get(invitations, to, MapSet.new())

    cond do
      is_nil(clan) ->
        {:error, :not_in_clan}

      not is_nil(current_clan) ->
        {:error, :already_in_clan}

      MapSet.member?(player_invitations, clan) ->
        {:error, :pending_invitation}

      true ->
        invitation = %Invitation{to: to, clan: clan}
        player_invitations = MapSet.put(player_invitations, clan)
        {:ok, invitation, %{state | invitations: Map.put(invitations, to, player_invitations)}}
    end
  end

  defp do_accept(invitation, %{members: members, invitations: invitations} = state) do
    player_invitations = Map.get(invitations, invitation.to, MapSet.new())

    cond do
      Map.has_key?(members, invitation.to) ->
        {:error, :already_in_clan}

      not MapSet.member?(player_invitations, invitation.clan) ->
        {:error, :no_invitation}

      true ->
        {:ok, %{state | members: Map.put(members, invitation.to, {invitation.clan, false}), invitations: Map.delete(invitations, invitation.to)}}
    end
  end

  defp do_decline(invitation, %{members: members, invitations: invitations} = state) do
    player_invitations = Map.get(invitations, invitation.to, MapSet.new())

    cond do
      Map.has_key?(members, invitation.to) ->
        {:error, :already_in_clan}

      not MapSet.member?(player_invitations, invitation.clan) ->
        {:error, :no_invitation}

      true ->
        player_invitations = MapSet.delete(player_invitations, invitation.clan)
        {:ok, %{state | invitations: Map.put(invitations, invitation.to, player_invitations)}}
    end
  end

  defp do_kick(leader, player, %{members: members} = state) do
    {leader_clan, leader?} = Map.get(members, leader, {nil, false})
    {player_clan, _} = Map.get(members, player, {nil, false})

    cond do
      not leader? ->
        {:error, :not_leader}

      player_clan != leader_clan ->
        {:error, :not_in_clan}

      true ->
        {:ok, %{state | members: Map.delete(members, player)}}
    end
  end

  defp do_find_clan(name, %{clans: clans, members: members}) do
    {clan_name, _is_leader} = Map.get(members, name, {nil, nil})
    clan = Map.get(clans, clan_name)

    cond do
      is_nil(clan_name) ->
        {:error, :not_in_clan}

      is_nil(clan) ->
        ## malformed clans db?
        {:error, :not_in_clan}

      true ->
        {:ok, clan}
    end
  end
end
