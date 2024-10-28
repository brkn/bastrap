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
  Converts a hand to an opponent's view where all cards are face down and not selectable.
  Used to prevent players from seeing other players' cards.

  ## Examples
      iex> hand = %Bastrap.Games.Hand{cards: [
      ...>   %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: false, selectable: true},
      ...>   %Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: true, selectable: true}
      ...> ]}
      iex> Bastrap.Games.Hand.to_opponent_hand(hand)
      %Bastrap.Games.Hand{cards: [
        %Bastrap.Games.Hand.Card{ranks: :face_down, selected: false, selectable: false},
        %Bastrap.Games.Hand.Card{ranks: :face_down, selected: true, selectable: false}
      ]}
  """
  @spec to_opponent_hand(t()) :: t()
  def to_opponent_hand(%__MODULE__{cards: cards} = hand) do
    cards
    |> Enum.map(fn hand_card -> %{hand_card | ranks: :face_down, selectable: false} end)
    |> then(&%{hand | cards: &1})
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

  def toggle_card_selection(%__MODULE__{cards: cards} = hand, selected_index) do
    with %{selectable: true} <- Enum.at(cards, selected_index) do
      cards
      |> Enum.with_index()
      |> Enum.map(fn
        {card, ^selected_index} -> %{card | selected: !card.selected}
        {card, _} -> card
      end)
      |> update_selectable_cards()
      |> then(fn new_cards -> %{hand | cards: new_cards} end)
      |> then(fn final_hand -> {:ok, final_hand} end)
    else
      _ -> {:error, :card_not_selectable}
    end
  end

  @doc """
  Removes the selected cards from the hand.

  ## Examples
    iex> hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}, {5, 6}])
    iex> hand = %{hand | cards: [
    ...>   %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: true, selectable: true},
    ...>   %Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: true, selectable: true},
    ...>   %Bastrap.Games.Hand.Card{ranks: {5, 6}, selected: false, selectable: true}
    ...> ]}
    iex> updated_hand = Bastrap.Games.Hand.remove_selected_cards(hand)
    iex> updated_hand.cards
    [%Bastrap.Games.Hand.Card{ranks: {5, 6}, selected: false, selectable: true}]
  """
  @spec remove_selected_cards(t()) :: t()
  def remove_selected_cards(%__MODULE__{cards: cards} = hand) do
    cards
    |> Enum.reject(& &1.selected)
    |> then(&%{hand | cards: &1})
  end

  @doc """
  Returns the selected cards as a card set.

  ## Examples
    iex> hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}, {5, 6}])
    iex> hand = %{hand | cards: [
    ...>   %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: true, selectable: true},
    ...>   %Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: false, selectable: true},
    ...>   %Bastrap.Games.Hand.Card{ranks: {5, 6}, selected: true, selectable: false},
    ...>   %Bastrap.Games.Hand.Card{ranks: {5, 3}, selected: false, selectable: false}
    ...> ]}
    iex> Bastrap.Games.Hand.selected_card_set(hand)
    [{1, 2}, {5, 6}]
  """
  @spec selected_card_set(t()) :: Deck.CardSet.t()
  def selected_card_set(%__MODULE__{cards: cards}) do
    cards
    |> Enum.filter(& &1.selected)
    |> Enum.map(& &1.ranks)
  end

  # TODO: Bug here.
  # Let's say hand looks like this [0, 1, 1, 1, 0, 0].
  # Middle card, at index 2 should be unclickable.
  # Only edge cards and outer neighbours should be selectable
  defp update_selectable_cards(cards) do
    cards
    |> selectable_indexes()
    |> then(fn selectable_indexes ->
      cards
      |> Enum.with_index()
      |> Enum.map(fn
        {card, index} -> %{card | selectable: Enum.member?(selectable_indexes, index)}
      end)
    end)
  end

  defp selectable_indexes(cards) do
    last_index = length(cards) - 1

    cards
    |> Enum.with_index()
    |> Enum.filter(fn {card, _} -> card.selected end)
    |> Enum.flat_map(fn
      {_, 0} -> [0, 1]
      {_, ^last_index} -> [last_index - 1, last_index]
      {_, index} -> [index - 1, index, index + 1]
    end)
    |> Enum.uniq()
    |> then(fn
      [] -> 0..last_index
      indexes -> indexes
    end)
  end
end
