defmodule Bastrap.Games.Deck.Card do
  @moduledoc """
  Represents a card in the deck.
  """

  @type rank :: 1..10
  @type t :: {rank, rank}

  @doc """
  Shuffles the given card.
  Shuffling a single card means just turning it upside down.

  ## Examples

      iex> card = {1, 2}
      iex> shuffled = Bastrap.Games.Deck.Card.shuffle(card)
      iex> shuffled == {1, 2} or shuffled == {2, 1}
      true

      iex> card = {5, 5}
      iex> Bastrap.Games.Deck.Card.shuffle(card)
      {5, 5}

      iex> card = {3, 7}
      iex> shuffled = Bastrap.Games.Deck.Card.shuffle(card)
      iex> shuffled in [{3, 7}, {7, 3}]
      true
  """
  @spec shuffle({rank, rank}) :: {rank, rank}
  def shuffle(card) do
    card
    |> Tuple.to_list()
    |> Enum.shuffle()
    |> List.to_tuple()
  end
end
