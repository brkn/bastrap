defmodule Bastrap.Games.Deck do
  @moduledoc """
  Represents a deck of cards in the game.
  """

  alias Bastrap.Games.Deck.Card
  alias Bastrap.Games.Hand

  @type card :: Card.t()

  @sorted_deck Enum.flat_map(1..9, fn num1 ->
                 Enum.map((num1 + 1)..10, fn num2 -> {num1, num2} end)
               end)

  # TODO: Fix the deleting card
  # @deck_for_2_players @sorted_deck |> List.delete({9, 10})
  @deck_for_4_players @sorted_deck |> List.delete({9, 10})

  @doc """
  Creates a new set of hands from shuffled deck of cards.
  TODO: add logger for the rand's seed value `:rand.seed(:exsss, {1, 2, 3})`

  ## Examples
      iex> Bastrap.Games.Deck.deal_hands(2)
      {:error, :invalid_player_count}

      iex> hands = Bastrap.Games.Deck.deal_hands(3)
      iex> length(hands) == 3 and Enum.all?(hands, fn hand -> length(hand.cards) == 15 end)
      true

      iex> hands = Bastrap.Games.Deck.deal_hands(4)
      iex> length(hands) == 4 and Enum.all?(hands, fn hand -> length(hand.cards) == 11 end)
      true

      iex> hands = Bastrap.Games.Deck.deal_hands(5)
      iex> length(hands) == 5 and Enum.all?(hands, fn hand -> length(hand.cards) == 9 end)
      true
  """
  @spec deal_hands(non_neg_integer()) :: {:error, :invalid_player_count} | list(list(card))
  def deal_hands(player_count) when player_count not in [3, 4, 5],
    do: {:error, :invalid_player_count}

  def deal_hands(player_count) do
    sorted_deck(player_count)
    |> Enum.map(&Card.maybe_flip(&1))
    |> Enum.shuffle()
    |> Enum.chunk_every(hand_length(player_count))
    |> Enum.map(&Hand.new(&1))
  end

  defp hand_length(player_count) do
    deck_length = player_count |> sorted_deck() |> length()

    trunc(deck_length / player_count)
  end

  defp sorted_deck(player_count) do
    case player_count do
      3 -> @sorted_deck
      4 -> @deck_for_4_players
      5 -> @sorted_deck
    end
  end
end
