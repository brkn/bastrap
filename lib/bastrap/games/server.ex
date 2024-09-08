defmodule Bastrap.Games.Server do
  use GenServer

  alias Phoenix.PubSub
  alias Bastrap.Games.Player

  def start_link(admin) do
    game_id = Ecto.UUID.generate()
    GenServer.start_link(__MODULE__, {admin, game_id}, name: via_tuple(game_id))
  end

  def init({admin, game_id}) do
    admin_player = Player.new(admin)

    game = %{
      id: game_id,
      state: :not_started,
      admin: admin_player,
      players: [admin_player],
      current_round: nil
    }

    broadcast_update(game)

    {:ok, game}
  end

  def handle_call(:get_id, _from, state), do: {:reply, state.id, state}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_cast({:join, user}, state) do
    if Enum.member?(state.players, user) do
      {:noreply, state}
    else
      new_player = Player.new(user)
      new_players = state.players ++ [new_player]
      new_state = %{state | players: new_players}

      broadcast_update(new_state)

      {:noreply, new_state}
    end
  end

  def handle_cast({:start_game, user}, state) do
    if state.admin.user != user do
      {:noreply, state}
    else
      new_state = %{state | state: :in_progress}

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
