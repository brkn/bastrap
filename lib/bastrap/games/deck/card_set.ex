defmodule Bastrap.Games.Deck.CardSet do
  @moduledoc """
  Represents a candidate set of cards for the player to play for the round.
  """

  alias Bastrap.Games.Deck.Card

  @type t :: list(Card.t())

  @doc """
  Determines the type of the card set.

  ## Examples
      iex> Bastrap.Games.Deck.CardSet.type([])
      :invalid

      iex> Bastrap.Games.Deck.CardSet.type([{1, 2}])
      :same_number

      iex> Bastrap.Games.Deck.CardSet.type([{1, 2}, {1, 3}])
      :same_number

      iex> Bastrap.Games.Deck.CardSet.type([{1, 2}, {2, 3}])
      :consecutive

      iex> Bastrap.Games.Deck.CardSet.type([{1, 2}, {3, 4}])
      :invalid
  """
  @spec type(t()) :: :consecutive | :same_number | :invalid
  def type(card_set) when length(card_set) == 0, do: :invalid
  def type(card_set) when length(card_set) == 1, do: :same_number

  def type(card_set) do
    case {same_number?(card_set), consecutive?(card_set)} do
      {true, _} -> :same_number
      {_, true} -> :consecutive
      {false, false} -> :invalid
    end
  end

  @doc """
  Checks if the card set consists of consecutive cards.

  ## Examples

      iex> Bastrap.Games.Deck.CardSet.consecutive?([{1, 2}])
      false

      iex> Bastrap.Games.Deck.CardSet.consecutive?([{1, 7}, {2, 3}])
      true

      iex> Bastrap.Games.Deck.CardSet.consecutive?([{1, 5}, {2, 3}, {3, 10}])
      true

      iex> Bastrap.Games.Deck.CardSet.consecutive?([{6, 4}, {7, 10}, {8, 1}])
      true

      iex> Bastrap.Games.Deck.CardSet.consecutive?([{1, 9}, {3, 10}])
      false
  """
  @spec consecutive?(t()) :: boolean
  def consecutive?(card_set) when length(card_set) == 1, do: false

  def consecutive?(card_set) do
    card_set
    |> Enum.map(&Card.main_value/1)
    |> Enum.sort()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [a, b] -> a == b - 1 end)
  end

  @doc """
  Checks if all cards in the set have the same main number.

  ## Examples

      iex> Bastrap.Games.Deck.CardSet.same_number?([{1, 2}])
      true

      iex> Bastrap.Games.Deck.CardSet.same_number?([{1, 2}, {1, 3}])
      true

      iex> Bastrap.Games.Deck.CardSet.same_number?([{1, 4}, {2, 4}])
      false

      iex> Bastrap.Games.Deck.CardSet.same_number?([{1, 4}, {1, 3}, {2, 4}])
      false
  """
  @spec same_number?(t()) :: boolean
  def same_number?(card_set) when length(card_set) == 1, do: true

  def same_number?(card_set) do
    card_set
    |> Enum.map(&Card.main_value/1)
    |> Enum.uniq()
    |> length() == 1
  end

  @doc """
  Checks if this card set is more powerful than the other card set.

  Rules:
  1. The set with more cards is always more powerful.
  2. For sets of the same size:
    a. A set of the same number is more powerful than a consecutive set.
    b. For two same number sets, higher card wins.
    c. For two consecutive sets, the one with the higher minimum value wins.

  ## Examples
      iex> same_card_set = [{1, 7}, {1, 5}]
      iex> other_same_card_set = [{1, 9}, {1, 6}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(same_card_set, other_same_card_set)
      false

      iex> same_card_set = [{2, 3}, {2, 1}]
      iex> other_same_card_set = [{1, 7}, {1, 10}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(same_card_set, other_same_card_set)
      true

      iex> same_card_set = [{2, 9}, {2, 6}]
      iex> other_same_card_set = [{10, 7}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(same_card_set, other_same_card_set)
      true

      iex> same_card_set = [{10, 7}]
      iex> other_same_card_set = [{2, 9}, {2, 6}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(same_card_set, other_same_card_set)
      false

      iex> consecutive_set = [{9, 1}, {10, 2}]
      iex> other_consecutive_set = [{2, 3}, {3, 4}, {4, 5}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(consecutive_set, other_consecutive_set)
      false

      iex> consecutive_set = [{1, 2}, {2, 3}, {3, 4}]
      iex> other_consecutive_set = [{2, 3}, {3, 4}, {4, 5}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(consecutive_set, other_consecutive_set)
      false

      iex> same_number_set = [{5, 1}, {5, 2}, {5, 3}]
      iex> consecutive_set_with_same_legth = [{1, 2}, {2, 3}, {3, 4}]
      iex> Bastrap.Games.Deck.CardSet.higher_than?(same_number_set, consecutive_set_with_same_legth)
      true
  """
  @spec higher_than?(t(), t()) :: boolean
  def higher_than?(card_set, other_card_set) when length(card_set) > length(other_card_set),
    do: true

  def higher_than?(card_set, other_card_set) when length(card_set) < length(other_card_set),
    do: false

  def higher_than?(card_set, other_card_set) when length(card_set) == length(other_card_set) do
    case {type(card_set), type(other_card_set)} do
      {:same_number, :same_number} ->
        Card.higher_than?(List.first(card_set), List.first(other_card_set))

      {:consecutive, :consecutive} ->
        min_value(card_set) > min_value(other_card_set)

      {:same_number, :consecutive} ->
        true

      {:consecutive, :same_number} ->
        false
    end
  end

  @doc """
  Returns the minimum value in the card set.

  ## Examples

      iex> Bastrap.Games.Deck.CardSet.min_value([{1, 2}, {2, 3}, {3, 4}])
      1

      iex> Bastrap.Games.Deck.CardSet.min_value([{6, 3}, {5, 4}, {4, 5}])
      4
  """
  @spec min_value(t()) :: Card.rank()
  def min_value(card_set) do
    card_set
    |> Enum.map(&Card.main_value/1)
    |> Enum.min()
  end
end
