defmodule Bastrap.Games.Round do
  @moduledoc """
  Represents the state of a round in the game.
  """

  alias Bastrap.Games.{Player, Deck}

  defstruct [:dealer_index, :turn_player_index, :players]

  @type t :: %__MODULE__{
          dealer_index: non_neg_integer(),
          turn_player_index: non_neg_integer(),
          players: list(Player.t())
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
  """
  @spec next_player_index(non_neg_integer(), pos_integer()) :: non_neg_integer()
  defp next_player_index(index, num_of_players), do: rem(index + 1, num_of_players)
end
