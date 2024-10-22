defmodule Bastrap.Games.Round do
  @moduledoc """
  Represents the state of a round in the game.
  """

  alias Bastrap.Games.{Player, Deck, CenterPile}

  defstruct [:dealer_index, :turn_player_index, :players, center_pile: CenterPile.new()]

  @type t :: %__MODULE__{
          dealer_index: non_neg_integer(),
          turn_player_index: non_neg_integer(),
          players: list(Player.t()),
          center_pile: CenterPile.t()
        }

  @doc """
  Creates a new round state with the given players and dealer.
  """
  @spec new(list(Player.t()), non_neg_integer()) :: t()
  def new(players, dealer_index) do
    hands = Deck.deal_hands(length(players))

    players_with_hands =
      Enum.zip(players, hands)
      |> Enum.map(fn {player, hand} -> %{player | hand: hand} end)

    turn_player_index = next_player_index(dealer_index, length(players))

    %__MODULE__{
      dealer_index: dealer_index,
      turn_player_index: turn_player_index,
      players: players_with_hands
    }
  end

  @doc """
  Advances the turn to the next player.

  ## Examples
    iex> round = %Bastrap.Games.Round{turn_player_index: 1, players: [%{}, %{}, %{}]}
    iex> Bastrap.Games.Round.pass_turn(round)
    %Bastrap.Games.Round{turn_player_index: 2, players: [%{}, %{}, %{}]}

    iex> round = %Bastrap.Games.Round{turn_player_index: 2, players: [%{}, %{}, %{}]}
    iex> Bastrap.Games.Round.pass_turn(round)
    %Bastrap.Games.Round{turn_player_index: 0, players: [%{}, %{}, %{}]}
  """
  @spec pass_turn(t()) :: t()
  def pass_turn(%__MODULE__{turn_player_index: turn_player_index, players: players} = round) do
    %{round | turn_player_index: next_player_index(turn_player_index, length(players))}
  end

  @doc """
  Calculates the index of the next player in the round.

  This function is used to determine which player should take the next turn.
  It wraps around to the first player (index 0) after the last player.

  ## Examples
    iex> Bastrap.Games.Round.next_player_index(0, 3)
    1
    iex> Bastrap.Games.Round.next_player_index(2, 3)
    0
  """
  @spec next_player_index(non_neg_integer(), pos_integer()) :: non_neg_integer()
  def next_player_index(index, num_of_players), do: rem(index + 1, num_of_players)

  @doc """
  Returns the player whose turn it currently is.

  ## Examples
    iex> players = [
    ...>   %Bastrap.Games.Player{user: %{id: 1}, display_name: "Alice"},
    ...>   %Bastrap.Games.Player{user: %{id: 2}, display_name: "Bob"},
    ...>   %Bastrap.Games.Player{user: %{id: 3}, display_name: "Charlie"}
    ...> ]
    iex> round = %Bastrap.Games.Round{turn_player_index: 1, players: players}
    iex> Bastrap.Games.Round.current_turn_player(round)
    %Bastrap.Games.Player{user: %{id: 2}, display_name: "Bob"}
  """
  @spec current_turn_player(t()) :: Player.t()
  def current_turn_player(%__MODULE__{turn_player_index: turn_player_index, players: players}) do
    players |> Enum.at(turn_player_index)
  end

  @doc """
  Checks if the round should end based on the current player's hand.

  Returns true if the current player's hand is empty,
  otherwise returns false

  ## Examples
    iex> player = %Bastrap.Games.Player{hand: %Bastrap.Games.Hand{cards: []}}
    iex> round = %Bastrap.Games.Round{players: [player], turn_player_index: 0}
    iex> Bastrap.Games.Round.should_end?(round)
    true

    iex> player = %Bastrap.Games.Player{hand: %Bastrap.Games.Hand{cards: [%Bastrap.Games.Hand.Card{}]}}
    iex> round = %Bastrap.Games.Round{players: [player], turn_player_index: 0}
    iex> Bastrap.Games.Round.should_end?(round)
    false
  """
  def should_end?(round) do
    round
    |> current_turn_player()
    |> then(fn player -> player.hand.cards end)
    |> then(fn
      [] -> true
      _ -> false
    end)
  end
end
