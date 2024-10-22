defmodule BastrapWeb.Game.CenterPileComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.AccountsFixtures
  alias Bastrap.Games
  alias Bastrap.Games.CenterPile

  @default_center_pile_ranks [{1, 2}, {3, 4}]

  describe "CenterPileComponent" do
    setup context do
      center_pile_ranks = context[:center_pile_ranks] || @default_center_pile_ranks
      num_of_users = context[:user_count] || 3

      admin = AccountsFixtures.user_fixture(%{email: "admin_email@example.com"})
      users = 1..num_of_users |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)

      {:ok, game} = Games.create_game(admin)

      Phoenix.PubSub.subscribe(Bastrap.PubSub, "game:#{game.id}")

      # Join users to the game
      users
      |> Enum.each(fn user ->
        {:ok, :joining} = Games.join_game(game.id, user)
        assert_receive {:game_update, _}, 500
      end)

      # Start the game
      {:ok, :starting} = Games.start_game(game.id, admin)
      assert_receive {:game_update, game}, 500

      # Mock the center pile with our test data
      # TODO: Handle this in a more sane and safe way.
      center_pile = CenterPile.new(center_pile_ranks)
      {:ok, game} = Games.setup_center_pile_for_test(game.id, center_pile)

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      %{view: view, game: game, admin: admin, users: users}
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
