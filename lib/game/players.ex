defmodule Game.Players do
  alias Game.Player

  use GenServer

  @type opt :: {:name, String.t()}
  @type opts :: [opt()]
  @type reason :: :name_already_exists

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec create(opts()) :: {:ok, Player.t()} | {:error, reason()}
  def create(opts) do
    player = %Player{name: Keyword.fetch!(opts, :name)}
    GenServer.call(__MODULE__, {:create, player})
  end

  @spec delete_all :: :ok
  def delete_all do
    GenServer.call(__MODULE__, :delete_all)
  end

  @impl GenServer
  def init(nil) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:create, player}, _from, state) do
    case do_create(player, state) do
      {:ok, new_state} ->
        {:reply, {:ok, player}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:delete_all, _from, _state) do
    {:reply, :ok, %{}}
  end

  defp do_create(player, players) do
    if Map.has_key?(players, player.name) do
      {:error, :name_already_exists}
    else
      {:ok, Map.put(players, player.name, player)}
    end
  end
end
