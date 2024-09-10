defmodule Bastrap.Games.RoundTest do
  use Bastrap.DataCase, async: true

  alias Bastrap.Games.Round
  alias Bastrap.Games.Player
  alias Bastrap.AccountsFixtures

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
        current_player_index: current_player_index,
        players: round_players
      } = Round.new(three_players, 0)

      assert dealer_index == 0
      assert current_player_index == 1
      assert length(round_players) == 3
      assert Enum.all?(round_players, fn %Player{hand: hand} -> length(hand) == 15 end)
    end

    test "wraps current player index when dealer is last player", %{players: players} do
      three_players = Enum.take(players, 3)

      %Round{dealer_index: dealer_index, current_player_index: current_player_index} =
        Round.new(three_players, 2)

      assert dealer_index == 2
      assert current_player_index == 0
    end

    test "distributes correct number of cards for 4 players", %{players: players} do
      four_players = Enum.take(players, 4)

      %Round{players: round_players} = Round.new(four_players, 0)

      assert length(round_players) == 4
      assert Enum.all?(round_players, fn %Player{hand: hand} -> length(hand) == 11 end)
    end

    test "distributes correct number of cards for 5 players", %{players: players} do
      %Round{players: round_players} = Round.new(players, 0)

      assert length(round_players) == 5
      assert Enum.all?(round_players, fn %Player{hand: hand} -> length(hand) == 9 end)
    end
  end
end
