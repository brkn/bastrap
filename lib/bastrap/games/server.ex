defmodule Bastrap.Games.Server do
  use GenServer

  alias Phoenix.PubSub

  def start_link(admin) do
    game_id = Ecto.UUID.generate()
    GenServer.start_link(__MODULE__, {admin, game_id}, name: via_tuple(game_id))
  end

  def init({admin, game_id}) do
    state = %{id: game_id, admin: admin, players: [admin]}
    broadcast_update(state)
    {:ok, state}
  end

  def handle_call(:get_id, _from, state), do: {:reply, state.id, state}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_cast({:join, user}, state) do
    if Enum.member?(state.players, user) do
      {:noreply, state}
    else
      new_players = [user | state.players]
      new_state = %{state | players: new_players}

      broadcast_update(new_state)

      {:noreply, new_state}
    end
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Bastrap.Games.Registry, game_id}}
  end

  defp broadcast_update(state) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{state.id}", {:game_update, state})
  end
end
