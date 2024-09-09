defmodule Bastrap.Games.Hand do
  @moduledoc """
  Represents a player's hand in the game.
  """
  alias Bastrap.Games.Deck

  defstruct cards: []

  @type t :: %__MODULE__{
          cards: list(Deck.card())
        }

  @doc """
  Creates a new hand with the given cards.

  ## Examples
      iex> Bastrap.Games.Hand.new([{10, 5}, {7, 3}])
      %Bastrap.Games.Hand{cards: [{10, 5}, {7, 3}]}

      iex> Bastrap.Games.Hand.new()
      %Bastrap.Games.Hand{cards: []}
  """
  @spec new(list(Deck.card())) :: t()
  def new(cards \\ []) do
    %__MODULE__{cards: cards}
  end

  @doc """
  Adds a card to the hand.

  ## Examples
      iex> hand = Bastrap.Games.Hand.new([{1, 2}])
      iex> Bastrap.Games.Hand.add_card(hand, {3, 4})
      %Bastrap.Games.Hand{cards: [{3, 4}, {1, 2}]}
  """
  @spec add_card(t(), Deck.card()) :: t()
  def add_card(%__MODULE__{} = hand, card) do
    %{hand | cards: [card | hand.cards]}
  end

  @doc """
  Removes a card from the hand.

  ## Examples
      iex> hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}])
      iex> Bastrap.Games.Hand.remove_card(hand, {1, 2})
      {:ok, %Bastrap.Games.Hand{cards: [{3, 4}]}}

      iex> hand = Bastrap.Games.Hand.new([{1, 2}])
      iex> Bastrap.Games.Hand.remove_card(hand, {3, 4})
      {:error, :card_not_found}
  """
  @spec remove_card(t(), Deck.card()) :: {:ok, t()} | {:error, :card_not_found}
  def remove_card(%__MODULE__{} = hand, card) do
    if card in hand.cards do
      {:ok, %{hand | cards: List.delete(hand.cards, card)}}
    else
      {:error, :card_not_found}
    end
  end
end
