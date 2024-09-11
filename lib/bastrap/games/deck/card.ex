defmodule Bastrap.Games.Deck.Card do
  @moduledoc """
  Represents a card in the deck.
  Each card is a tuple of two ranks.
  The first rank is considered the main value that is active in the round.
  """

  @type rank :: 1..10
  @type t :: {rank, rank}

  @doc """
  50% of the time turns the card upside down
  50% of the time returns the card in same direction

  ## Examples

      iex> card = {1, 2}
      iex> shuffled = Bastrap.Games.Deck.Card.maybe_flip(card)
      iex> shuffled == {1, 2} or shuffled == {2, 1}
      true

      iex> card = {5, 5}
      iex> Bastrap.Games.Deck.Card.maybe_flip(card)
      {5, 5}

      iex> card = {3, 7}
      iex> shuffled = Bastrap.Games.Deck.Card.maybe_flip(card)
      iex> shuffled in [{3, 7}, {7, 3}]
      true
  """
  @spec maybe_flip(t()) :: t()
  def maybe_flip(card) do
    card
    |> Tuple.to_list()
    |> Enum.shuffle()
    |> List.to_tuple()
  end

  @doc """
  Returns the main value of the card, which is the first element of the tuple.

  ## Examples

      iex> Bastrap.Games.Deck.Card.main_value({3, 7})
      3

      iex> Bastrap.Games.Deck.Card.main_value({10, 1})
      10
  """
  @spec main_value(t()) :: rank
  def main_value(card) do
    elem(card, 0)
  end

  @doc """
  Checks if the first card is higher than the second card.
  A card is considered higher if its main value is greater.

  ## Examples

      iex> Bastrap.Games.Deck.Card.higher_than?({5, 2}, {3, 7})
      true

      iex> Bastrap.Games.Deck.Card.higher_than?({3, 7}, {5, 2})
      false

      iex> Bastrap.Games.Deck.Card.higher_than?({5, 2}, {5, 7})
      false
  """
  @spec higher_than?(t(), t()) :: boolean
  def higher_than?(card, other_card) do
    main_value(card) > main_value(other_card)
  end

  @doc """
  Real life version of this method would be turning the card upside down

  Examples
  iex> Bastrap.Games.Deck.Card.flip({1, 2})
  {2, 1}

  iex> Bastrap.Games.Deck.Card.flip({5, 5})
  {5, 5}

  iex> Bastrap.Games.Deck.Card.flip({7, 3})
  {3, 7}
  """
  @spec flip(t()) :: t()
  def flip(card) do
    card
    |> Tuple.to_list()
    |> Enum.reverse()
    |> List.to_tuple()
  end
end
