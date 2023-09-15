defmodule Game.Clans do
  alias Game.{Clan, Player}

  use GenServer

  @type opt :: {:name, String.t()} | {:tag, String.t()}
  @type opts :: [opt()]
  @type reason :: :name_already_exists | :tag_already_exists | :already_in_clan

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec create(Player.t(), opts()) :: {:ok, Clan.t()} | {:error, reason()}
  def create(player, opts) do
    clan = %Clan{
      name: Keyword.fetch!(opts, :name),
      tag: Keyword.fetch!(opts, :tag),
      leader_name: player.name
    }

    GenServer.call(__MODULE__, {:create, clan})
  end

  @spec delete_all :: :ok
  def delete_all do
    GenServer.call(__MODULE__, :delete_all)
  end

  @impl GenServer
  def init(nil) do
    {:ok, %{clans: %{}, members: %{}, tags: %{}}}
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

  def handle_call(:delete_all, _from, _state) do
    {:reply, :ok, %{clans: %{}, members: %{}, tags: %{}}}
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
end
