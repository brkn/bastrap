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
