defmodule Game.Clans do
  alias Game.{Clan, Player}
  alias Game.ClanInvitation, as: Invitation

  use GenServer

  @type opt :: {:name, String.t()} | {:tag, String.t()}
  @type opts :: [opt()]
  @type create_error :: :name_already_exists | :tag_already_exists | :already_in_clan
  @type invite_error :: :already_in_clan | :not_allowed | :not_in_clan | :pending_invitation

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

  def handle_call(:delete_all, _from, _state) do
    {:reply, :ok, %{clans: %{}, members: %{}, tags: %{}, invitations: %{}}}
  end

  defp do_create(clan, %{clans: clans, tags: tags, members: members} = state) do
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
             members: Map.put(members, clan.leader_name, clan.name)
         }}
    end
  end

  defp do_invite(from, to, %{members: members, invitations: invitations} = state) do
    from_clan = Map.get(members, from)
    to_clan = Map.get(members, to)

    cond do
      is_nil(from_clan) ->
        {:error, :not_in_clan}

      not is_nil(to_clan) ->
        {:error, :already_in_clan}

      Map.has_key?(invitations, {from, to}) ->
        {:error, :pending_invitation}

      true ->
        invitation = %Invitation{
          from: from,
          to: to,
          clan: from_clan
        }

        {:ok, invitation, %{state | invitations: Map.put(invitations, {from, to}, invitation)}}
    end
  end
end
