defmodule Bastrap.Games.Game do
  @moduledoc """
  Manages game progression and player interactions.
  Handles the core game rules like starting the game, joining players, taking turns, managing hands, and scoring.
  """

  alias Bastrap.Games.{Player, Round, Hand}

  @type game_state :: :not_started | :in_progress | :scoring

  @type t :: %__MODULE__{
          id: String.t(),
          state: game_state(),
          admin: Player.t(),
          players: list(Player.t()),
          current_round: Round.t() | nil
        }

  defstruct [:id, :admin, :players, :current_round, state: :not_started]

  @doc """
  Creates a new game with the given ID and admin user.
  The admin is automatically added as the first player.

  ## Examples
    iex> user = %Bastrap.Accounts.User{id: 1, email: "admin@example.com"}
    iex> game = Bastrap.Games.Game.new("game-123", user)
    iex> %Bastrap.Games.Game{
    ...>    id: "game-123",
    ...>    admin: %Bastrap.Games.Player{user: %{id: 1}},
    ...>    players: [%Bastrap.Games.Player{}],
    ...>    current_round: nil,
    ...>    state: :not_started
    ...>  } = game
  """
  @spec new(String.t(), Bastrap.Accounts.User.t()) :: t()
  def new(id, admin) do
    admin_player = Player.new(admin)

    %__MODULE__{
      id: id,
      admin: admin_player,
      players: [admin_player],
      current_round: nil
    }
  end

  @doc """
  Attempts to add a new player to the game.
  Returns error if game has already started or player is already in the game.

  ## Examples
      iex> admin = %Bastrap.Accounts.User{id: 1, email: "admin@example.com"}
      iex> user = %Bastrap.Accounts.User{id: 2, email: "user@example.com"}
      iex> game = Bastrap.Games.Game.new("game-123", admin)
      iex> {:ok, updated_game} = Bastrap.Games.Game.join(game, user)
      iex> %Bastrap.Games.Game{
      ...>  players: [
      ...>    %Bastrap.Games.Player{user: ^admin},
      ...>    %Bastrap.Games.Player{user: ^user}
      ...>  ]
      ...>} = updated_game

      iex> admin = %Bastrap.Accounts.User{id: 1, email: "admin@example.com"}
      iex> user = %Bastrap.Accounts.User{id: 2, email: "user@example.com"}
      iex> game = Bastrap.Games.Game.new("game-123", admin)
      iex> game = %{game | state: :in_progress}
      iex> Bastrap.Games.Game.join(game, user)
      {:error, :game_already_started}
  """
  @spec join(t(), Bastrap.Accounts.User.t()) :: {:ok, t()} | {:error, atom()}
  def join(%{state: :in_progress}, _user), do: {:error, :game_already_started}

  def join(%{players: players} = game, user) do
    if Enum.any?(players, &(&1.user.id == user.id)) do
      {:ok, game}
    else
      {:ok, %{game | players: players ++ [Player.new(user)]}}
    end
  end

  @doc """
  Attempts to start the game.
  Returns error if user is not admin or not enough players (min 3).

  ## Examples
      iex> admin = %Bastrap.Accounts.User{id: 1, email: "admin@example.com"}
      iex> user1 = %Bastrap.Accounts.User{id: 2, email: "user1@example.com"}
      iex> user2 = %Bastrap.Accounts.User{id: 3, email: "user2@example.com"}
      iex> game = Bastrap.Games.Game.new("game-123", admin)
      iex> {:ok, game} = Bastrap.Games.Game.join(game, user1)
      iex> {:ok, game} = Bastrap.Games.Game.join(game, user2)
      iex> {:ok, started_game} = Bastrap.Games.Game.start(game, admin)
      iex> started_game.state
      :in_progress

      iex> admin = %Bastrap.Accounts.User{id: 1, email: "admin@example.com"}
      iex> user1 = %Bastrap.Accounts.User{id: 2, email: "user1@example.com"}
      iex> user2 = %Bastrap.Accounts.User{id: 3, email: "user2@example.com"}
      iex> game = Bastrap.Games.Game.new("game-123", admin)
      iex> {:ok, game} = Bastrap.Games.Game.join(game, user1)
      iex> {:ok, game} = Bastrap.Games.Game.join(game, user2)
      iex> Bastrap.Games.Game.start(game, user1)
      {:error, :not_admin}
  """
  @spec start(t(), Bastrap.Accounts.User.t()) :: {:ok, t()} | {:error, atom()}
  def start(game, _) when length(game.players) < 3, do: {:error, :not_enough_players}
  def start(game, _) when length(game.players) > 5, do: {:error, :too_many_players}

  def start(%{state: :not_started, players: players} = game, user) do
    if game.admin.user != user do
      {:error, :not_admin}
    else
      # Why not handle dealer_index at Round.new method?
      # Because at next round we want to make the dealer the next player
      dealer_index = Enum.random(0..(length(players) - 1))
      current_round = Round.new(players, dealer_index)
      new_game = %__MODULE__{game | state: :in_progress, current_round: current_round}

      {:ok, new_game}
    end
  end

  def start(_game, _user), do: {:error, :already_started}

  @doc """
  Starts the next round by updating total scores and rotating the dealer.
  Only the admin can start next round and game must be in scoring state.
  """
  @spec start_next_round(t(), Bastrap.Accounts.User.t()) :: {:ok, t()} | {:error, atom()}
  def start_next_round(%{state: :scoring, players: players} = game, user) do
    if game.admin.user != user do
      {:error, :not_admin}
    else
      updated_game_players =
        Enum.zip(players, game.current_round.players)
        |> Enum.map(fn {game_player, round_player} ->
          %{
            game_player
            | current_score: game_player.current_score + Player.net_round_score(round_player)
          }
        end)

      new_round = Round.create_next_round(game.current_round)
      new_game = %__MODULE__{
        game
        | players: updated_game_players,
          state: :in_progress,
          current_round: new_round
      }

      {:ok, new_game}
    end
  end

  def start_next_round(_, _user), do: {:error, :invalid_state_transition}

  @doc """
  Returns the player whose turn it currently is.

  ## Examples
      iex> admin = %Bastrap.Accounts.User{id: 1, email: "admin@example.com"}
      iex> user1 = %Bastrap.Accounts.User{id: 2, email: "user1@example.com"}
      iex> user2 = %Bastrap.Accounts.User{id: 3, email: "user2@example.com"}
      iex> game = Bastrap.Games.Game.new("game-123", admin)
      iex> {:ok, game} = Bastrap.Games.Game.join(game, user1)
      iex> {:ok, game} = Bastrap.Games.Game.join(game, user2)
      iex> {:ok, started_game} = Bastrap.Games.Game.start(game, admin)
      iex> %Bastrap.Games.Player{user: %Bastrap.Accounts.User{}} = Bastrap.Games.Game.current_turn_player(started_game)
  """
  @spec current_turn_player(t()) :: Player.t()
  def current_turn_player(%{current_round: round}), do: Round.current_turn_player(round)

  @doc """
  Attempts to select a card in a player's hand.
  Returns error if card index is invalid or game hasn't started.
  """
  @spec select_card(t(), %{card_index: integer(), player_id: integer()}) ::
          {:ok, t()} | {:error, atom()}
  def select_card(%{state: :in_progress} = game, %{card_index: index, player_id: player_id}) do
    with {:ok, player} <- find_player_by_id(game, player_id),
         {:ok, updated_hand} <- Hand.toggle_card_selection(player.hand, index) do
      {:ok, update_player_hand(game, player_id, updated_hand)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def select_card(_, _), do: {:error, :invalid_game_state}

  @doc """
  Attempts to submit selected cards from the current turn player.
  Returns the updated game state and score if successful.
  Returns error if the selected cards don't form a valid set or aren't higher than center pile.
  """
  @spec submit_selected_cards(t()) :: {:ok, t(), non_neg_integer()} | {:error, atom()}
  def submit_selected_cards(%{state: :not_started}), do: {:error, :invalid_game_state}

  def submit_selected_cards(game) do
    case Round.submit_selected_cards(game.current_round) do
      {:ok, updated_round, score} ->
        case Round.should_end?(updated_round) do
          true -> handle_end_round(game, updated_round, score)
          false -> handle_continue_round(game, updated_round, score)
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Finds a player in the game by their user ID.
  """
  @spec find_player_by_id(t(), integer()) :: {:ok, Player.t()} | {:error, :player_not_found}
  def find_player_by_id(game, player_id) do
    game.current_round.players
    |> Enum.find(&(&1.user.id == player_id))
    |> case do
      nil -> {:error, :player_not_found}
      player -> {:ok, player}
    end
  end

  @doc """
  Updates the current round with new state.
  Validates the round is consistent with game rules before updating.

  """
  @spec update_round(t(), Round.t() | nil) :: {:ok, t()} | {:error, atom()}
  def update_round(%{state: :not_started}, _), do: {:error, :no_active_round}
  def update_round(_game, nil), do: {:error, :no_active_round}

  def update_round(game, round) do
    {:ok, %{game | current_round: round}}
  end

  defp update_player_hand(game, player_id, new_hand) do
    game.current_round.players
    |> Enum.map(fn
      %{user: %{id: ^player_id}} = player -> %{player | hand: new_hand}
      other_player -> other_player
    end)
    |> then(fn updated_players -> %{game.current_round | players: updated_players} end)
    |> then(fn updated_round -> %{game | current_round: updated_round} end)
  end

  defp handle_end_round(game, _round, score) do
    {:ok, %{game | state: :scoring}, score}
  end

  defp handle_continue_round(game, round, score) do
    round
    |> Round.pass_turn()
    |> then(fn updated_round -> %{game | current_round: updated_round} end)
    |> then(&{:ok, &1, score})
  end
end
