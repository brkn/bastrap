defmodule Bastrap.Games.Server do
  use GenServer

  alias Phoenix.PubSub

  def start_link(admin) do
    game_id = Ecto.UUID.generate()
    GenServer.start_link(__MODULE__, {admin, game_id}, name: via_tuple(game_id))
  end

  def init({admin, game_id}) do
    game = %{id: game_id, state: :not_started, admin: admin, players: [admin]}
    broadcast_update(game)
    {:ok, game}
  end

  def handle_call(:get_id, _from, state), do: {:reply, state.id, state}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_cast({:join, user}, state) do
    if Enum.member?(state.players, user) do
      {:noreply, state}
    else
      new_players = state.players ++ [user]
      new_state = %{state | players: new_players}

      broadcast_update(new_state)

      {:noreply, new_state}
    end
  end

  # def handle_cast(:start_game, _from, state) do
  #   new_state = %{state | state: :in_progress}

  #   broadcast_update(new_state)

  #   {:reply, :ok, new_state}
  # end

  defp via_tuple(game_id) do
    {:via, Registry, {Bastrap.Games.Registry, game_id}}
  end

  defp broadcast_update(state) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{state.id}", {:game_update, state})
  end
end
