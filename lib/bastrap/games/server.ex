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

  def handle_call(:get_id, _from, game), do: {:reply, game.id, game}
  def handle_call(:get_game, _from, game), do: {:reply, game, game}

  def handle_cast({:join, user}, game) do
    if Enum.member?(game.players, user) do
      {:noreply, game}
    else
      new_player = Player.new(user)
      new_players = game.players ++ [new_player]
      new_game = %{game | players: new_players}

      broadcast_update(new_game)

      {:noreply, new_game}
    end
  end

  def handle_cast({:start_game, user}, game) do
    if game.admin.user != user do
      {:noreply, game}
    else
      new_game = %{game | state: :in_progress}

      broadcast_update(new_game)

      {:noreply, new_game}
    end
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Bastrap.Games.Registry, game_id}}
  end

  defp broadcast_update(game) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{game.id}", {:game_update, game})
  end
end
