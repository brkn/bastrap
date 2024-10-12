defmodule Bastrap.Games.Hand.Card do
  @moduledoc """
  Represents a card in a player's hand.

  This module differs from `Deck.Card` as it includes additional attributes
  specific to a card in a player's hand, such as whether it's selected or selectable.
  """

  alias Bastrap.Games.Deck.Card, as: DeckCard

  @type rank :: DeckCard.rank()

  @type t :: %__MODULE__{
          ranks: {rank, rank} | :face_down,
          selected: boolean(),
          selectable: boolean()
        }

  defstruct [:ranks, selected: false, selectable: false]

  @doc """
  Creates a new hand card from a deck card.

  ## Examples
    iex> deck_card = {1, 2}
    iex> Bastrap.Games.Hand.Card.new(deck_card)
    %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: false, selectable: false}

    iex> Bastrap.Games.Hand.Card.new(:face_down)
    %Bastrap.Games.Hand.Card{ranks: :face_down, selected: false, selectable: false}
  """
  @spec new(DeckCard.t() | :face_down, keyword()) :: t()
  def new(deck_card, opts \\ []) do
    selected = Keyword.get(opts, :selected, false)
    selectable = Keyword.get(opts, :selectable, false)

    %__MODULE__{
      ranks: deck_card,
      selected: selected,
      selectable: selectable
    }
  end

  @doc """
  Returns a boolean representing if a card is face down or not.
  A face-down card represents an opponent's card, which you can't see.

  ## Examples
    iex> card = Bastrap.Games.Hand.Card.new({1, 2})
    iex> Bastrap.Games.Hand.Card.face_down?(card)
    false

    iex> card = Bastrap.Games.Hand.Card.new(:face_down)
    iex> Bastrap.Games.Hand.Card.face_down?(card)
    true
  """
  @spec face_down?(t()) :: boolean()
  def face_down?(card), do: card.ranks == :face_down

  @doc """
  Flips the card, reversing the order of its ranks.
  If the card is face down, it remains unchanged.

  ## Examples
    iex> card = Bastrap.Games.Hand.Card.new({1, 2})
    iex> Bastrap.Games.Hand.Card.flip(card)
    %Bastrap.Games.Hand.Card{ranks: {2, 1}, selected: false, selectable: false}

    iex> card = Bastrap.Games.Hand.Card.new(:face_down)
    iex> Bastrap.Games.Hand.Card.flip(card)
    %Bastrap.Games.Hand.Card{ranks: :face_down, selected: false, selectable: false}
  """
  @spec flip(t()) :: t()
  def flip(%__MODULE__{ranks: :face_down} = card), do: card

  def flip(%__MODULE__{ranks: ranks} = card) do
    %__MODULE__{card | ranks: DeckCard.flip(ranks)}
  end

  @doc """
  Returns the main value of the card, which is the first element of the ranks tuple.
  Returns nil for a face-down card.

  ## Examples
    iex> card = Bastrap.Games.Hand.Card.new({3, 7})
    iex> Bastrap.Games.Hand.Card.main_value(card)
    3

    iex> card = Bastrap.Games.Hand.Card.new(:face_down)
    iex> Bastrap.Games.Hand.Card.main_value(card)
    nil
  """
  @spec main_value(t()) :: rank() | nil
  def main_value(%__MODULE__{ranks: :face_down}), do: nil
  def main_value(%__MODULE__{ranks: {main, _}}), do: main

  @doc """
  Sets the selected status of the card.

  ## Examples
    iex> card = Bastrap.Games.Hand.Card.new({1, 2})
    iex> Bastrap.Games.Hand.Card.set_selected(card, true)
    %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: true, selectable: false}
  """
  @spec set_selected(t(), boolean()) :: t()
  def set_selected(card, selected) do
    %{card | selected: selected}
  end
end
