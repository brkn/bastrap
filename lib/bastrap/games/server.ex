defmodule Bastrap.Games.Server do
  use GenServer

  alias Phoenix.PubSub
  alias Bastrap.Games.{Player, Round}

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

  def handle_cast({:start_game, _user}, game) when length(game.players) < 3 do
    broadcast_game_error(game, "Need at least 3 players to start the game")

    {:noreply, game}
  end

  def handle_cast({:start_game, _user}, game) when length(game.players) > 5 do
    broadcast_game_error(game, "Can't have more than 5 players")

    {:noreply, game}
  end

  def handle_cast({:start_game, user}, game) do
    if game.admin.user != user do
      {:noreply, game}
    else
      # Why not handle dealer_index at Round.new method?
      # Because at next round we want to make the dealer the next player
      dealer_index = Enum.random(0..(length(game.players) - 1))
      current_round = Round.new(game.players, dealer_index)

      new_game = %{game | state: :in_progress, current_round: current_round}
      broadcast_update(new_game)

      {:noreply, new_game}
    end
  end

  # Not sure if we ever need end_round, after each action we shall check if round is ended
  # TODO: Next dealer finding logic is inside this extract it
  # def handle_cast(:end_round, game) do
  #   last_dealer_index = game.current_round.dealer_index
  #   new_dealer_index = rem(last_dealer_index + 1, length(game.players))

  #   # current_round = Round.new(game.players, new_dealer_index)

  #   # TODO: Check if game is ended, if so, state is :ended
  #   new_game = %{game | state: :in_progress, current_round: current_round}

  #   broadcast_update(new_game)

  #   {:noreply, new_game}
  # end

  # TODO: handle cancellation of the turn action.
  # Maybe not for the first version of the game?

  # TODO: add method called handle_select_card
  # def handle_cast({:select_card, user, card_index}, game) do
  # # validate if the player's the current_player
  # # validate if card is selectable
  # # if invalid return error
  # # if valid then mark the card as selected and assign new_hand to the user

  # TODO: add method called handle_submit.
  # Maybe signature would look like this:
  # def handle_cast({:submit_turn, user}, game) do
  # # validate via creating a card_set from the selected cards of the player's hand.
  # # validate if the player's the current_player
  # # validate if selected card indexes are consecutive.
  # # if invalid return error
  # # if valid then filters over the hand's of the player and filter out the selected cards
  # Submiting removes all selected cards upon succcess message from the server
  # This means we should track the selected cards somehow

  defp via_tuple(game_id) do
    {:via, Registry, {Bastrap.Games.Registry, game_id}}
  end

  defp broadcast_update(game) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{game.id}", {:game_update, game})
  end

  defp broadcast_game_error(game, message) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{game.id}", {:game_error, message})
  end
end
