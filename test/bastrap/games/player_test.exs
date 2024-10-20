defmodule Bastrap.Games.PlayerTest do
  use ExUnit.Case, async: true

  alias Bastrap.Games.Player
  alias Bastrap.Games.Hand
  alias Bastrap.Games.Hand.Card, as: HandCard

  doctest Bastrap.Games.Player

  describe "new/1" do
    test "creates a new player with the given user" do
      user = %Bastrap.Accounts.User{id: 1, email: "test@example.com"}
      player = Player.new(user)

      assert %Player{} = player
      assert player.user == user
      assert player.display_name == "test"
      assert %Hand{cards: []} = player.hand
      assert player.current_score == 0
    end
  end

  describe "increase_score/2" do
    test "increases the player's score" do
      player = %Player{current_score: 10}
      updated_player = Player.increase_score(player, 5)

      assert updated_player.current_score == 15
    end

    test "doesn't change score when adding zero" do
      player = %Player{current_score: 10}
      updated_player = Player.increase_score(player, 0)

      assert updated_player.current_score == 10
    end
  end

  describe "remove_selected_cards/1" do
    test "removes selected cards from the player's hand" do
      hand = %Hand{
        cards: [
          %HandCard{ranks: {1, 2}, selected: true},
          %HandCard{ranks: {3, 4}, selected: false},
          %HandCard{ranks: {5, 6}, selected: true}
        ]
      }

      player = %Player{hand: hand}

      updated_player = Player.remove_selected_cards(player)

      assert [%HandCard{ranks: {3, 4}, selected: false}] = updated_player.hand.cards
    end

    test "doesn't change hand when no cards are selected" do
      hand = %Hand{
        cards: [
          %HandCard{ranks: {1, 2}, selected: false},
          %HandCard{ranks: {3, 4}, selected: false}
        ]
      }

      player = %Player{hand: hand}

      updated_player = Player.remove_selected_cards(player)

      assert updated_player.hand == hand
    end
  end
end
