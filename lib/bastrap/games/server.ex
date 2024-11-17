defmodule Bastrap.Games.Server do
  @moduledoc """
  GenServer implementation for managing game state and player interactions.
  Handles game lifecycle, authorization, and broadcasting updates to connected clients.
  """

  use GenServer

  alias Phoenix.PubSub
  alias Bastrap.Games.Game

  @table_name :games_table

  @doc """
  Starts a new game server with the given admin user.
  Returns `{:ok, pid}` if successful.
  """
  def start_link({admin, game_id}) do
    GenServer.start_link(__MODULE__, {admin, game_id}, name: via_tuple(game_id))
  end

  @impl true
  def init({admin, game_id}) do
    game =
      case :ets.lookup(@table_name, game_id) do
        [{^game_id, saved_game}] -> saved_game
        [] -> Game.new(game_id, admin)
      end

    broadcast_update(game)
    {:ok, game}
  end

  @impl true
  def handle_call(:get_id, _from, game), do: {:reply, game.id, game}

  @impl true
  def handle_call(:get_game, _from, game), do: {:reply, game, game}

  @impl true
  def handle_call({:put_game, new_game}, _, _game) do
    broadcast_update(new_game)

    {:reply, new_game, new_game}
  end

  @impl true
  def handle_cast({:join, user}, %{state: :not_started} = game) do
    with {:ok, updated_game} <- Game.join(game, user) do
      updated_game
      |> tap(&broadcast_update/1)
      |> then(&{:noreply, &1})
    else
      {:error, reason} ->
        game
        |> tap(&broadcast_game_error(&1, reason))
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_cast({:start_game, user}, game) do
    with :ok <- authorize_game_admin(game, user),
         {:ok, updated_game} <- Game.start(game, user) do
      updated_game
      |> tap(&broadcast_update/1)
      |> then(&{:noreply, &1})
    else
      {:error, reason} ->
        game
        |> tap(&broadcast_game_error(&1, reason))
        |> then(&{:noreply, &1})
    end
  end

  @impl true
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

  @impl true
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

  @impl true
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
    :ets.insert(@table_name, {game.id, game})

    PubSub.broadcast(Bastrap.PubSub, "game:#{game.id}", {:game_update, game})
  end

  defp broadcast_game_error(game, message) do
    PubSub.broadcast(
      Bastrap.PubSub,
      "game:#{game.id}",
      {:game_error, Bastrap.Games.ErrorHandler.humanize(message)}
    )
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
end
