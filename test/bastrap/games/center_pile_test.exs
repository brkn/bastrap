defmodule Bastrap.Games.CenterPileTest do
  use ExUnit.Case, async: true
  alias Bastrap.Games.CenterPile
  alias Bastrap.Games.Hand.Card, as: HandCard

  doctest Bastrap.Games.CenterPile

  describe "new/1" do
    test "creates an empty center pile" do
      assert %CenterPile{cards: []} = CenterPile.new()
    end

    test "creates a center pile with cards, marking edge cards as selectable" do
      pile = CenterPile.new([{1, 2}, {3, 4}, {5, 6}])

      assert %CenterPile{
               cards: [
                 %HandCard{ranks: {1, 2}, selectable: true, selected: false},
                 %HandCard{ranks: {3, 4}, selectable: false, selected: false},
                 %HandCard{ranks: {5, 6}, selectable: true, selected: false}
               ]
             } = pile
    end

    test "creates a center pile with a single card, marking it as selectable" do
      pile = CenterPile.new([{1, 2}])

      assert %CenterPile{
               cards: [
                 %HandCard{ranks: {1, 2}, selectable: true, selected: false}
               ]
             } = pile
    end
  end

  describe "select_left/1" do
    test "selects the leftmost card and updates the pile" do
      pile = CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
      {:ok, selected, updated_pile} = CenterPile.select_left(pile)
      assert selected == %HandCard{ranks: {1, 2}, selectable: true, selected: false}
      assert updated_pile == CenterPile.new([{3, 4}, {5, 6}])
    end

    test "returns an error when the pile is empty" do
      assert {:error, :empty_pile} = CenterPile.select_left(CenterPile.new())
    end
  end

  describe "select_right/1" do
    test "selects the rightmost card and updates the pile" do
      pile = CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
      {:ok, selected, updated_pile} = CenterPile.select_right(pile)
      assert selected == %HandCard{ranks: {5, 6}, selectable: true, selected: false}
      assert updated_pile == CenterPile.new([{1, 2}, {3, 4}])
    end

    test "returns an error when the pile is empty" do
      assert {:error, :empty_pile} = CenterPile.select_right(CenterPile.new())
    end
  end

  describe "empty?/1" do
    test "returns true for an empty pile" do
      assert CenterPile.empty?(CenterPile.new())
    end

    test "returns false for a non-empty pile" do
      refute CenterPile.empty?(CenterPile.new([{1, 2}]))
    end
  end

  describe "size/1" do
    test "returns 0 for an empty pile" do
      assert CenterPile.size(CenterPile.new()) == 0
    end

    test "returns the correct size for a non-empty pile" do
      assert CenterPile.size(CenterPile.new([{1, 2}, {3, 4}])) == 2
    end
  end

  describe "select_card/2" do
    test "selects a card at a valid index" do
      pile = CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
      {:ok, updated_pile} = CenterPile.select_card(pile, 0)

      assert updated_pile.cards == [
               %HandCard{ranks: {1, 2}, selectable: true, selected: true},
               %HandCard{ranks: {3, 4}, selectable: false, selected: false},
               %HandCard{ranks: {5, 6}, selectable: false, selected: false}
             ]
    end

    test "returns an error for an invalid index" do
      pile = CenterPile.new([{1, 2}, {3, 4}, {5, 6}])
      assert {:error, :invalid_index} = CenterPile.select_card(pile, 1)
    end
  end
end
