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
                %Bastrap.Games.Hand.Card{ranks: {10, 5}, selected: false, selectable: true},
                %Bastrap.Games.Hand.Card{ranks: {7, 3}, selected: false, selectable: true}
              ]
            }

      iex> Bastrap.Games.Hand.new()
      %Bastrap.Games.Hand{cards: []}
  """
  @spec new(list(Deck.card())) :: t()
  def new(list_of_ranks \\ []) do
    list_of_ranks
    |> Enum.map(fn ranks -> HandCard.new(ranks, selectable: true) end)
    |> then(fn hand_cards -> %__MODULE__{cards: hand_cards} end)
  end

  @doc """
  Selects a card in the hand at the given index.

  ## Examples
    iex> hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}, {5, 6}])
    iex> {:ok, updated_hand} = Bastrap.Games.Hand.toggle_card_selection(hand, 1)
    iex> updated_hand
    %Bastrap.Games.Hand{
      cards: [
        %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: false, selectable: true},
        %Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: true, selectable: true},
        %Bastrap.Games.Hand.Card{ranks: {5, 6}, selected: false, selectable: true}
      ]
    }
  """
  @spec toggle_card_selection(t(), non_neg_integer()) ::
          {:ok, t()} | {:error, :invalid_index | :card_not_selectable}
  def toggle_card_selection(_, selected_index) when not is_integer(selected_index),
    do: {:error, :invalid_index}

  def toggle_card_selection(_, selected_index) when selected_index < 0,
    do: {:error, :invalid_index}

  def toggle_card_selection(%__MODULE__{cards: cards}, selected_index)
      when selected_index >= length(cards),
      do: {:error, :invalid_index}

  def toggle_card_selection(hand, selected_index) do
    case Enum.at(hand.cards, selected_index) do
      %{selectable: false} ->
        {:error, :card_not_selectable}

      _ ->
        hand.cards
        |> Enum.with_index()
        |> Enum.map(fn
          {card, ^selected_index} -> %{card | selected: !card.selected}
          {card, _} -> card
        end)
        |> then(fn new_cards -> %{hand | cards: new_cards} end)
        |> then(fn new_hand -> {:ok, new_hand} end)
    end
  end

  # TODO: DELETE the remove card concept. Server should handle removing via a method called: remove_selected.
  @doc """
  Removes a card from the hand.

  ## Examples
      iex> hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}])
      iex> Bastrap.Games.Hand.remove_card(hand, {1, 2})
      {:ok, %Bastrap.Games.Hand{cards: [%Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: false, selectable: true}]}}

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
