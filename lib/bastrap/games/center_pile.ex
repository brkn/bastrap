defmodule Bastrap.Games.CenterPile do
  alias Bastrap.Games.Deck
  alias Bastrap.Games.Hand.Card, as: HandCard

  defstruct cards: []

  @type t :: %__MODULE__{
          cards: list(HandCard.t())
        }

  @doc """
  Creates a new center pile with the given cards, marking only the leftmost and rightmost cards as selectable.

  ## Examples
    iex> Bastrap.Games.CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
    %Bastrap.Games.CenterPile{cards: [
      %Bastrap.Games.Hand.Card{ranks: {1, 2}, selectable: true, selected: false},
      %Bastrap.Games.Hand.Card{ranks: {3, 4}, selectable: false, selected: false},
      %Bastrap.Games.Hand.Card{ranks: {5, 6}, selectable: true, selected: false}
    ]}

    iex> Bastrap.Games.CenterPile.new([])
    %Bastrap.Games.CenterPile{cards: []}
  """
  @spec new(list(Deck.card())) :: t()
  def new(list_of_ranks \\ []) do
    cards =
      list_of_ranks
      |> Enum.with_index()
      |> Enum.map(fn
        {ranks, 0} -> HandCard.new(ranks, selectable: true)
        {ranks, i} when i == length(list_of_ranks) - 1 -> HandCard.new(ranks, selectable: true)
        {ranks, _} -> HandCard.new(ranks, selectable: false)
      end)

    %__MODULE__{cards: cards}
  end

  @doc """
  Selects the leftmost card from the center pile.
  Returns the selected card and the updated center pile.

  ## Examples
    iex> pile = Bastrap.Games.CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
    iex> {:ok, selected, updated_pile} = Bastrap.Games.CenterPile.select_left(pile)
    iex> selected.ranks
    {1, 2}
    iex> updated_pile.cards
    [
      %Bastrap.Games.Hand.Card{ranks: {3, 4}, selectable: true, selected: false},
      %Bastrap.Games.Hand.Card{ranks: {5, 6}, selectable: true, selected: false}
    ]
  """
  @spec select_left(t()) :: {:ok, HandCard.t(), t()} | {:error, :empty_pile}
  def select_left(%__MODULE__{cards: []}), do: {:error, :empty_pile}

  def select_left(%__MODULE__{cards: [card | rest]}) do
    updated_pile = new(Enum.map(rest, & &1.ranks))
    {:ok, card, updated_pile}
  end

  @doc """
  Selects the rightmost card from the center pile.
  Returns the selected card and the updated center pile.

  ## Examples
    iex> pile = Bastrap.Games.CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
    iex> {:ok, selected, updated_pile} = Bastrap.Games.CenterPile.select_right(pile)
    iex> selected.ranks
    {5, 6}
    iex> updated_pile.cards
    [
      %Bastrap.Games.Hand.Card{ranks: {1, 2}, selectable: true, selected: false},
      %Bastrap.Games.Hand.Card{ranks: {3, 4}, selectable: true, selected: false}
    ]
  """
  @spec select_right(t()) :: {:ok, HandCard.t(), t()} | {:error, :empty_pile}
  def select_right(%__MODULE__{cards: []}), do: {:error, :empty_pile}

  def select_right(%__MODULE__{cards: cards}) do
    {rest, [card]} = Enum.split(cards, -1)
    updated_pile = new(Enum.map(rest, & &1.ranks))
    {:ok, card, updated_pile}
  end

  @doc """
  Checks if the center pile is empty.

  ## Examples
    iex> Bastrap.Games.CenterPile.empty?(Bastrap.Games.CenterPile.new())
    true

    iex> pile = Bastrap.Games.CenterPile.new([{1, 2}])
    iex> Bastrap.Games.CenterPile.empty?(pile)
    false
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{cards: cards}), do: Enum.empty?(cards)

  @doc """
  Returns the number of cards in the center pile.

  ## Examples
    iex> pile = Bastrap.Games.CenterPile.new([{1, 2}, {3, 4}])
    iex> Bastrap.Games.CenterPile.size(pile)
    2
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{cards: cards}), do: length(cards)

  @doc """
  Marks a card in the center pile as selected.

  ## Examples
    iex> pile = Bastrap.Games.CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
    iex> {:ok, updated_pile} = Bastrap.Games.CenterPile.select_card(pile, 0)
    iex> updated_pile.cards
    [
      %Bastrap.Games.Hand.Card{ranks: {1, 2}, selectable: true, selected: true},
      %Bastrap.Games.Hand.Card{ranks: {3, 4}, selectable: false, selected: false},
      %Bastrap.Games.Hand.Card{ranks: {5, 6}, selectable: false, selected: false}
    ]
  """
  @spec select_card(t(), non_neg_integer()) :: {:ok, t()} | {:error, :invalid_index}
  def select_card(%__MODULE__{cards: cards} = pile, index) when index in [0, length(cards) - 1] do
    updated_cards =
      cards
      |> Enum.with_index()
      |> Enum.map(fn
        {card, ^index} -> %{card | selected: true}
        {card, _} -> %{card | selected: false, selectable: false}
      end)

    {:ok, %{pile | cards: updated_cards}}
  end

  def select_card(_, _), do: {:error, :invalid_index}
end
