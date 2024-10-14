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

    turn_player_index = rem(dealer_index + 1, length(players))

    %__MODULE__{
      dealer_index: dealer_index,
      turn_player_index: turn_player_index,
      players: players_with_hands
    }
  end
end
