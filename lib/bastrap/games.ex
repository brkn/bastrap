defmodule Bastrap.Games do
  alias Phoenix.PubSub

  def create_game(admin) do
    case Bastrap.Games.Supervisor.create_game(admin) do
      {:ok, pid} ->
        game_id = GenServer.call(pid, :get_id)
        {:ok, %{id: game_id, pid: pid}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def join_game(game_id, user) do
    case game_pid(game_id) do
      {:ok, pid} -> GenServer.cast(pid, {:join, user}) |> then(fn _ -> {:ok, :joining} end)
      _ -> {:error, :not_found}
    end
  end

  def start_game(game_id, user) do
    case game_pid(game_id) do
      {:ok, pid} -> GenServer.cast(pid, {:start_game, user}) |> then(fn _ -> {:ok, :starting} end)
      _ -> {:error, :not_found}
    end
  end

  def get_game(game_id) do
    case game_pid(game_id) do
      {:ok, pid} -> {:ok, GenServer.call(pid, :get_game)}
      _ -> {:error, :not_found}
    end
  end

  def subscribe_to_game(game_id) do
    PubSub.subscribe(Bastrap.PubSub, "game:#{game_id}")
  end

  defp game_pid(game_id) do
    case Registry.lookup(Bastrap.Games.Registry, game_id) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end
end
