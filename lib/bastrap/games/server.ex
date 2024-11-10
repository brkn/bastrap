defmodule Bastrap.Games.Server do
  use GenServer

  alias Phoenix.PubSub
  alias Bastrap.Games.Game

  def start_link(admin) do
    game_id = Ecto.UUID.generate()
    GenServer.start_link(__MODULE__, {admin, game_id}, name: via_tuple(game_id))
  end

  def init({admin, game_id}) do
    game = Game.new(game_id, admin)
    broadcast_update(game)
    {:ok, game}
  end

  def handle_call(:get_id, _from, game), do: {:reply, game.id, game}
  def handle_call(:get_game, _from, game), do: {:reply, game, game}
  def handle_call({:put_game, new_game}, _, _game), do: {:reply, new_game, new_game}

  def handle_cast({:join, user}, %{state: :not_started} = game) do
    with {:ok, updated_game} <- Game.join(game, user) do
      broadcast_update(updated_game)
      {:noreply, updated_game}
    else
      {:error, reason} ->
        broadcast_game_error(game, reason)
        {:noreply, game}
    end
  end

  def handle_cast({:start_game, user}, game) do
    with :ok <- authorize_game_admin(game, user),
         {:ok, updated_game} <- Game.start(game, user) do
      broadcast_update(updated_game)
      {:noreply, updated_game}
    else
      {:error, reason} ->
        broadcast_game_error(game, reason)
        {:noreply, game}
    end
  end

  def handle_cast({:start_next_round, user}, game) do
    with :ok <- authorize_game_admin(game, user),
         {:ok, updated_game} <- Game.start_next_round(game, user) do
      broadcast_update(updated_game)
      {:noreply, updated_game}
    else
      {:error, reason} ->
        broadcast_game_error(game, reason)
        {:noreply, game}
    end
  end

  def handle_cast({:select_card, user, card_position}, %{state: :in_progress} = game) do
    with {:ok, card_owner} <- Game.find_player_by_id(game, card_position.player_id),
         :ok <- authorize_player_for_select_card(user, card_owner),
         {:ok, updated_game} <- Game.select_card(game, card_position) do
      broadcast_update(updated_game)
      {:noreply, updated_game}
    else
      {:error, reason} ->
        broadcast_game_error(game, reason)
        {:noreply, game}
    end
  end

  def handle_cast({:submit_selected_cards, user}, game) do
    with {:ok, current_player} <- Game.find_player_by_id(game, user.id),
         {:ok, turn_player} <- {:ok, Game.current_turn_player(game)},
         :ok <- authorize_player_for_submit_cards(current_player, turn_player),
         {:ok, updated_game, _score} <- Game.submit_selected_cards(game) do
      broadcast_update(updated_game)
      {:noreply, updated_game}
    else
      {:error, reason} ->
        broadcast_game_error(game, reason)
        {:noreply, game}
    end
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Bastrap.Games.Registry, game_id}}
  end

  defp broadcast_update(game) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{game.id}", {:game_update, game})
  end

  defp broadcast_game_error(game, message) do
    PubSub.broadcast(Bastrap.PubSub, "game:#{game.id}", {:game_error, humanize_error(message)})
  end

  defp authorize_player_for_select_card(user, card_owner) do
    if user.id == card_owner.user.id,
      do: :ok,
      else: {:error, "You can only select your own cards"}
  end

  defp authorize_game_admin(game, user) do
    if game.admin.user.id == user.id, do: :ok, else: {:error, :not_admin}
  end

  defp authorize_player_for_submit_cards(current_player, turn_player) do
    if current_player.user.id == turn_player.user.id do
      :ok
    else
      {:error, :not_your_turn}
    end
  end

  defp humanize_error(:not_enough_players), do: "Need at least 3 players to start the game"
  defp humanize_error(:too_many_players), do: "Can't have more than 5 players"
  defp humanize_error(:not_your_turn), do: "Not your turn"
  defp humanize_error(:card_set_not_higher), do: "Selected cards must be higher than center pile"
  defp humanize_error(:card_not_selectable), do: "Card is not selectable"
  defp humanize_error(:invalid_index), do: "Invalid card index"
  defp humanize_error(error) when is_binary(error), do: error
  defp humanize_error(_), do: "An error occurred"
end
