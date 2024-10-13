defmodule Bastrap.Games.Hand do
  @moduledoc """
  Represents a player's hand in the game.
  """
  alias Bastrap.Games.Deck
  alias Bastrap.Games.Hand.Card, as: HandCard

  defstruct cards: []

  @type t :: %__MODULE__{
          cards: list(HandCard.t())
        }

  @doc """
  Creates a new hand with the given cards.

  ## Examples
      iex> Bastrap.Games.Hand.new([{10, 5}, {7, 3}])
      %Bastrap.Games.Hand{
              cards: [
                %Bastrap.Games.Hand.Card{ranks: {10, 5}, selected: false, selectable: false},
                %Bastrap.Games.Hand.Card{ranks: {7, 3}, selected: false, selectable: false}
              ]
            }

      iex> Bastrap.Games.Hand.new()
      %Bastrap.Games.Hand{cards: []}
  """
  @spec new(list(Deck.card())) :: t()
  def new(list_of_ranks \\ []) do
    list_of_ranks
    |> Enum.map(fn ranks -> HandCard.new(ranks) end)
    |> then(fn hand_cards -> %__MODULE__{cards: hand_cards} end)
  end

  # TODO: ADD select_card method
  # This means we should track the selected cards, and know the selectable cards.
  # If no cards are selected then all cards are selectable.
  # I've tried storing this information at the card struct, but thta doesnt makes sense at hand module
  # When selecting a card we would have to mutate multiple cards state's selectable and selected attributes.

  # TODO: DELETE the remove card concept. Server should handle removing via a method called: remove_selected.
  @doc """
  Removes a card from the hand.

  ## Examples
      iex> hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}])
      iex> Bastrap.Games.Hand.remove_card(hand, {1, 2})
      {:ok, %Bastrap.Games.Hand{cards: [%Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: false, selectable: false}]}}

      iex> hand = Bastrap.Games.Hand.new([{1, 2}])
      iex> Bastrap.Games.Hand.remove_card(hand, {3, 4})
      {:error, :card_not_found}
  """
  @spec remove_card(t(), Deck.card()) :: {:ok, t()} | {:error, :card_not_found}
  def remove_card(%__MODULE__{} = hand, deck_card) do
    index = Enum.find_index(hand.cards, fn hand_card -> hand_card.ranks == deck_card end)

    if index do
      new_cards = List.delete_at(hand.cards, index)

      {:ok, %{hand | cards: new_cards}}
    else
      {:error, :card_not_found}
    end
  end
end
