defmodule BastrapWeb.Game.ScoringComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bastrap.AccountsFixtures
  alias Bastrap.GameFixtures

  alias Bastrap.Games

  describe "ScoringComponent" do
    setup do
      admin = AccountsFixtures.user_fixture(%{email: "admin_email@example.com"})

      {:ok, %{id: game_id}} = Games.create_game(admin)
      {:ok, game} = Games.get_game(game_id)

      game =
        game
        |> GameFixtures.start_game(player_count: 3)
        |> GameFixtures.update_player(0, fn player ->
          %{player | current_score: 5, hand: %Bastrap.Games.Hand{cards: []}}
        end)
        |> GameFixtures.update_player(1, fn player ->
          %{player | current_score: 2, hand: Bastrap.Games.Hand.new([{4, 5}, {1, 2}])}
        end)
        |> Map.put(:state, :scoring)
        |> Bastrap.Games.put_game()

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(game.admin.user)
        |> live(~p"/games/#{game.id}")

      %{view: view, game: game}
    end

    test "renders players scores", %{view: view, game: game} do
      assert view |> has_element?("#round-winner", game.admin.display_name)
      assert view |> has_element?("#player-score-#{game.admin.user.id}", "5")
    end
  end
end
