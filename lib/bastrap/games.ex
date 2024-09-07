defmodule Bastrap.Games do
  alias Phoenix.PubSub

  def create_game(admin) do
    case Bastrap.Games.Supervisor.start_game(admin.id) do
      {:ok, pid} ->
        game_id = GenServer.call(pid, :get_id)
        {:ok, %{id: game_id, pid: pid}}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_game(game_id) do
    case Registry.lookup(Bastrap.Games.Registry, game_id) do
      [{pid, _}] -> {:ok, GenServer.call(pid, :get_state)}
      [] -> {:error, :not_found}
    end
  end

  def subscribe_to_game(game_id) do
    PubSub.subscribe(Bastrap.PubSub, "game:#{game_id}")
  end
end
