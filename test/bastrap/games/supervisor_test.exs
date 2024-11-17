defmodule Bastrap.Games.SupervisorTest do
  use Bastrap.DataCase, async: true

  alias Bastrap.AccountsFixtures
  alias Bastrap.GameFixtures

  alias Bastrap.Games.Supervisor
  alias Bastrap.Games

  setup do
    users = Enum.map(1..2, fn _ -> AccountsFixtures.user_fixture() end)
    %{users: users}
  end

  describe "start_game/1" do
    test "starts a new game server", %{users: [user | _]} do
      assert {:ok, pid} = Supervisor.create_game(user)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "starts multiple game servers", %{users: [user1, user2]} do
      assert {:ok, pid1} = Supervisor.create_game(user1)
      assert {:ok, pid2} = Supervisor.create_game(user2)

      assert is_pid(pid1)
      assert is_pid(pid2)
      assert pid1 != pid2
      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
    end
  end

  describe "supervisor" do
    test "is started with the application" do
      supervisor_pid = Process.whereis(Bastrap.Games.Supervisor)
      assert is_pid(supervisor_pid)
      assert Process.alive?(supervisor_pid)
    end
  end

  describe "supervisor recovery" do
    setup do
      user = AccountsFixtures.user_fixture()
      {:ok, %{id: game_id, pid: pid}} = Games.create_game(user)

      %{game_id: game_id, pid: pid, user: user}
    end

    test "restarts game server when it crashes", %{game_id: game_id, pid: pid, user: user} do
      # Force kill the game server
      Process.exit(pid, :kill)

      # Wait briefly for supervisor to restart
      Process.sleep(10)

      # Look up new pid
      [{new_pid, _}] = Registry.lookup(Bastrap.Games.Registry, game_id)

      assert Process.alive?(new_pid)
      assert pid != new_pid

      # Verify game state was recovered
      assert {:ok, game} = Games.get_game(game_id)
      assert game.admin.user.id == user.id
      assert game.state == :not_started
    end

    test "restarts game server and recovers complex game state", %{game_id: game_id} do
      original_game =
        game_id
        |> Games.get_game()
        |> then(fn {:ok, game} -> game end)
        |> GameFixtures.start_game(player_count: 3, dealer_index: 2)
        |> GameFixtures.update_player_total_score(1, 0)
        |> GameFixtures.update_player_total_score(2, -5)
        |> GameFixtures.update_player(0, fn p ->
          hand = Bastrap.Games.Hand.new([{1, 2}, {3, 4}])
          %{p | hand: hand, current_score: 5}
        end)
        |> Games.put_game()

      [{pid, _}] = Registry.lookup(Bastrap.Games.Registry, original_game.id)

      Process.exit(pid, :kill)
      Process.sleep(10)

      {:ok, recovered_game} = Games.get_game(original_game.id)

      assert recovered_game.state == :in_progress
      assert recovered_game.admin == original_game.admin
      assert same_order_of_players?(original_game.players, recovered_game.players)

      recovered_total_scores = recovered_game.players |> Enum.map(& &1.current_score)
      original_total_scores = original_game.players |> Enum.map(& &1.current_score)
      assert recovered_total_scores == original_total_scores

      recovered_round_scores =
        recovered_game.current_round.players |> Enum.map(& &1.current_score)

      original_round_scores = original_game.current_round.players |> Enum.map(& &1.current_score)
      assert recovered_round_scores == original_round_scores

      recovered_hands = recovered_game.players |> Enum.map(& &1.hand)
      original_hands = original_game.players |> Enum.map(& &1.hand)
      assert recovered_hands == original_hands
    end
  end

  defp same_order_of_players?(players, new_round_players) do
    Enum.map(new_round_players, & &1.user.id) == Enum.map(players, & &1.user.id)
  end
end
