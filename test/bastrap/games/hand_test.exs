defmodule Bastrap.Games.HandTest do
  use ExUnit.Case, async: true

  alias Bastrap.Games.Hand
  alias Bastrap.Games.Hand.Card, as: HandCard

  doctest Bastrap.Games.Hand

  @default_sample_hand_ranks [{1, 2}, {3, 4}, {3, 6}, {2, 8}, {9, 10}]

  describe "toggle_card_selection/2" do
    setup context do
      hand_ranks = context[:hand_ranks] || @default_sample_hand_ranks
      hand = context[:hand] || Hand.new(hand_ranks)

      %{hand: hand}
    end

    test "selects an unselected card in the hand", %{hand: hand} do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 1)

      assert %Hand{} = updated_hand
      assert length(updated_hand.cards) == length(hand.cards)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: {1, 2}, selected: false, selectable: true},
                 %HandCard{ranks: {3, 4}, selected: true, selectable: true},
                 %HandCard{ranks: {3, 6}, selected: false, selectable: true},
                 %HandCard{ranks: {2, 8}, selected: false, selectable: false},
                 %HandCard{ranks: {9, 10}, selected: false, selectable: false}
               ]
             }
    end

    test "makes neighbors selectable when a card is selected", %{
      hand: hand
    } do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 2)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: {1, 2}, selected: false, selectable: false},
                 %HandCard{ranks: {3, 4}, selected: false, selectable: true},
                 %HandCard{ranks: {3, 6}, selected: true, selectable: true},
                 %HandCard{ranks: {2, 8}, selected: false, selectable: true},
                 %HandCard{ranks: {9, 10}, selected: false, selectable: false}
               ]
             }
    end

    test "makes a single neighbor selectable when an edge card is selected", %{
      hand: hand
    } do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 4)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: {1, 2}, selected: false, selectable: false},
                 %HandCard{ranks: {3, 4}, selected: false, selectable: false},
                 %HandCard{ranks: {3, 6}, selected: false, selectable: false},
                 %HandCard{ranks: {2, 8}, selected: false, selectable: true},
                 %HandCard{ranks: {9, 10}, selected: true, selectable: true}
               ]
             }
    end

    @tag hand: %Hand{
           cards: [
             %HandCard{ranks: {1, 2}, selected: true, selectable: true},
             %HandCard{ranks: {3, 4}, selected: false, selectable: true},
             %HandCard{ranks: {3, 6}, selected: false, selectable: false},
             %HandCard{ranks: {2, 8}, selected: false, selectable: false},
             %HandCard{ranks: {9, 10}, selected: false, selectable: true}
           ]
         }
    test "selecting a card doesnt change the selectability of non-neighbour cards", %{
      hand: hand
    } do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 4)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: {1, 2}, selected: true, selectable: true},
                 %HandCard{ranks: {3, 4}, selected: false, selectable: true},
                 %HandCard{ranks: {3, 6}, selected: false, selectable: false},
                 %HandCard{ranks: {2, 8}, selected: false, selectable: true},
                 %HandCard{ranks: {9, 10}, selected: true, selectable: true}
               ]
             }
    end

    @tag hand: %Hand{
           cards: [
             HandCard.new({1, 2}, selected: true),
             HandCard.new({7, 9}, selected: false, selectable: true)
           ]
         }
    test "selects an unselected card in the hand when another card is already selected", %{
      hand: hand
    } do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 1)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: {1, 2}, selected: true, selectable: true},
                 %HandCard{ranks: {7, 9}, selected: true, selectable: true}
               ]
             }
    end

    @tag hand: %Hand{cards: [HandCard.new({1, 2}, selected: true, selectable: true)]}
    test "unselects a card in the hand", %{hand: hand} do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 0)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: {1, 2}, selected: false, selectable: true}
               ]
             }
    end

    @tag hand: Hand.new([:face_down])
    test "selects a card even when the card is face down", %{hand: hand} do
      {:ok, updated_hand} = Hand.toggle_card_selection(hand, 0)

      assert updated_hand == %Hand{
               cards: [
                 %HandCard{ranks: :face_down, selected: true, selectable: true}
               ]
             }
    end

    @tag hand: %Hand{cards: [HandCard.new({1, 2}, selected: false, selectable: false)]}
    test "returns an error when the card at the index is not selectable", %{hand: hand} do
      assert {:error, :card_not_selectable} = Hand.toggle_card_selection(hand, 0)
    end

    @tag hand: Hand.new()
    test "returns an error when the hand is empty", %{hand: hand} do
      assert {:error, :invalid_index} = Hand.toggle_card_selection(hand, 0)
    end

    test "returns an error when the index is out of bounds", %{hand: hand} do
      assert {:error, :invalid_index} = Hand.toggle_card_selection(hand, 5)
    end

    test "returns an error when the index is negative", %{hand: hand} do
      assert {:error, :invalid_index} = Hand.toggle_card_selection(hand, -1)
    end
  end
end
