defmodule BastrapWeb.Game.ScoringComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bastrap.{Games, AccountsFixtures, GameFixtures}

  describe "ScoringComponent" do
    setup do
      admin = AccountsFixtures.user_fixture(%{email: "admin@example.com"})
      {:ok, %{id: game_id}} = Games.create_game(admin)
      {:ok, game} = Games.get_game(game_id)

      game =
        game
        |> GameFixtures.start_game(player_count: 3)
        |> GameFixtures.update_player_total_score(0, 15)
        |> GameFixtures.update_player_total_score(1, 10)
        |> GameFixtures.update_player_total_score(2, 5)
        # Set round end state - player1 emptied hand and won
        |> GameFixtures.update_player(0, fn p ->
          %{p | hand: %Bastrap.Games.Hand{cards: []}, current_score: 2}
        end)
        |> GameFixtures.update_player(1, fn p ->
          %{p | hand: Bastrap.Games.Hand.new([{4, 5}, {1, 2}]), current_score: 7}
        end)
        |> GameFixtures.update_player(2, fn p ->
          %{p | hand: Bastrap.Games.Hand.new([{3, 6}]), current_score: -5}
        end)
        |> Map.put(:state, :scoring)
        |> Games.put_game()

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      %{view: view, game: game}
    end

    test "renders starting scores from previous rounds", %{view: view} do
      assert view |> element("#player-admin-starting-score") |> render() =~ "15"
      assert view |> element("#player-p1-starting-score") |> render() =~ "10"
      assert view |> element("#player-p2-starting-score") |> render() =~ "5"
    end

    test "renders penalty scores based on remaining cards", %{view: view} do
      assert view |> element("#player-admin-penalty-score") |> render() =~ "0"
      assert view |> element("#player-p1-penalty-score") |> render() =~ "-2"
      assert view |> element("#player-p2-penalty-score") |> render() =~ "-1"
    end

    test "renders points earned during the round", %{view: view} do
      assert view |> element("#player-admin-round-score") |> render() =~ "+2"
      assert view |> element("#player-p1-round-score") |> render() =~ "+7"
      assert view |> element("#player-p2-round-score") |> render() =~ "-5"
    end

    test "calculates correct final total scores", %{view: view} do
      # admin: 15 (total) + 2 (round) - 0 (penalties) = 17
      assert view |> element("#player-admin-total-score") |> render() =~ "17"

      # player1: 10 (total) + 7 (round) - 2 (penalties) = 15
      assert view |> element("#player-p1-total-score") |> render() =~ "15"

      # player2: 5 (total) - 5 (round) - 1 (penalties) = -1
      assert view |> element("#player-p2-total-score") |> render() =~ "-1"
    end

    test "identifies round winner", %{view: view} do
      # Only admin (index 0) has empty hand in our setup
      # Winner should have winner indication
      assert view
             |> element("#scoring-container li:first-child")
             |> render() =~ "🎉 Round Winner"

      refute view
             |> element("#scoring-container li:nth-child(2)")
             |> render() =~ "🎉 Round Winner"

      refute view
             |> element("#scoring-container li:nth-child(3)")
             |> render() =~ "🎉 Round Winner"
    end

    test "for admin renders Start Next Round button", %{view: admin_view} do
      assert admin_view |> has_element?("button", "Start Next Round")
    end

    test "for non-admin player does not render Start Next Round button", %{game: game} do
      non_admin_player = Enum.at(game.players, 1)

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(non_admin_player.user)
        |> live(~p"/games/#{game.id}")

      refute view |> has_element?("button", "Start Next Round")
    end

    test "for non-admin player renders waiting for admin to start next round message", %{
      conn: conn,
      game: game
    } do
      non_admin_player = Enum.at(game.players, 1)

      {:ok, view, _html} =
        conn
        |> log_in_user(non_admin_player.user)
        |> live(~p"/games/#{game.id}")

      assert view
             |> has_element?("#waiting-message", "Waiting for game admin to start next round")

      refute view |> has_element?("button", "Start Next Round")
    end

    test "when Start Next Round button is clicked transitions the game to a new round", %{
      view: view,
      game: game
    } do
      game |> GameFixtures.subscribe()

      view |> element("button", "Start Next Round") |> render_click()
      assert_receive {:game_update, updated_game}, 500

      assert updated_game.state == :in_progress

      refute view |> has_element?("#scoring-container")
    end
  end
end
