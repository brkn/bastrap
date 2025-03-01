defmodule Bastrap.Games.RoundTest do
  use Bastrap.DataCase, async: true

  alias Bastrap.Games.Round
  alias Bastrap.Games.Player
  alias Bastrap.Games.Hand
  alias Bastrap.AccountsFixtures

  doctest Bastrap.Games.Round

  describe "Round.new/2" do
    setup do
      players =
        1..5
        |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)
        |> Enum.map(&Player.new/1)

      %{players: players}
    end

    test "creates a round with correct structure for 3 players", %{players: players} do
      three_players = Enum.take(players, 3)

      %Round{
        dealer_index: dealer_index,
        turn_player_index: turn_player_index,
        players: round_players
      } = Round.new(three_players, 0)

      assert dealer_index == 0
      assert turn_player_index == 1
      assert length(round_players) == 3

      assert Enum.all?(round_players, fn %Player{hand: %Hand{cards: cards}} ->
               length(cards) == 15
             end)
    end

    test "wraps current player index when dealer is last player", %{players: players} do
      three_players = Enum.take(players, 3)

      %Round{dealer_index: dealer_index, turn_player_index: turn_player_index} =
        Round.new(three_players, 2)

      assert dealer_index == 2
      assert turn_player_index == 0
    end

    test "distributes correct number of cards for 4 players", %{players: players} do
      four_players = Enum.take(players, 4)

      %Round{players: round_players} = Round.new(four_players, 0)

      assert length(round_players) == 4

      assert Enum.all?(round_players, fn %Player{hand: %Hand{cards: cards}} ->
               length(cards) == 11
             end)
    end

    test "distributes correct number of cards for 5 players", %{players: players} do
      %Round{players: round_players} = Round.new(players, 0)

      assert length(round_players) == 5

      assert Enum.all?(round_players, fn %Player{hand: %Hand{cards: cards}} ->
               length(cards) == 9
             end)
    end
  end

  describe "Round.create_next_round/1" do
    setup do
      players =
        1..3
        |> Enum.with_index()
        |> Enum.map(fn {_, index} -> AccountsFixtures.user_fixture(id: index) end)
        |> Enum.map(&Player.new/1)
        |> Enum.with_index()
        |> Enum.map(fn
          {player, index} -> %{player | current_score: index * 2 + 1}
        end)

      %{players: players}
    end

    test "creates new round with rotated dealer and reset scores", %{players: players} do
      old_round = %Round{
        dealer_index: 2,
        players: players
      }

      next_round = Round.create_next_round(old_round)

      assert next_round.dealer_index == 0
      assert next_round.players |> Enum.all?(&(&1.current_score == 0))

      assert next_round.players |> Enum.map(& &1.user.id) ==
               old_round.players |> Enum.map(& &1.user.id)
    end
  end
end
