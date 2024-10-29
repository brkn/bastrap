defmodule BastrapWeb.Game.CenterPileComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bastrap.AccountsFixtures
  alias Bastrap.GameFixtures

  alias Bastrap.Games
  # alias Bastrap.Games.CenterPile

  @default_center_pile_ranks [{1, 2}, {3, 4}]

  describe "CenterPileComponent" do
    setup context do
      center_pile_ranks = context[:center_pile_ranks] || @default_center_pile_ranks
      num_of_users = context[:user_count] || 3

      admin = AccountsFixtures.user_fixture(%{email: "admin_email@example.com"})

      {:ok, %{id: game_id}} = Games.create_game(admin)
      {:ok, game} = Games.get_game(game_id)

      game =
        game
        |> GameFixtures.start_game(player_count: num_of_users, turn_player_index: 0)
        |> GameFixtures.with_center_pile(center_pile_ranks)
        |> Games.put_game()
        |> GameFixtures.subscribe()

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      %{view: view, game: game}
    end

    test "renders center pile cards", %{view: view} do
      assert has_element?(view, "#center-pile")
      assert has_element?(view, "#center-pile-card-0")
      assert has_element?(view, "#center-pile-card-1")

      # FIXME, stronger assertions. Assert the card element's text fully.
      assert view |> element("#center-pile-card-0") |> render() =~ "1"
      assert view |> element("#center-pile-card-0") |> render() =~ "2"
      assert view |> element("#center-pile-card-1") |> render() =~ "3"
      assert view |> element("#center-pile-card-1") |> render() =~ "4"
    end

    @tag center_pile_ranks: []
    test "renders empty center pile without rendering any card", %{view: view} do
      assert has_element?(view, "#center-pile")
      refute has_element?(view, "[id^='center-pile-card-']")
    end

    @tag center_pile_ranks: [{1, 2}, {3, 4}, {5, 6}]
    test "renders selectable cards correctly", %{view: view} do
      assert view |> element("#center-pile-card-0") |> render() =~ "cursor-pointer"
      refute view |> element("#center-pile-card-1") |> render() =~ "cursor-pointer"
      assert view |> element("#center-pile-card-2") |> render() =~ "cursor-pointer"
    end
  end
end
