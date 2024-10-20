defmodule BastrapWeb.Game.RoundComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.AccountsFixtures
  alias Bastrap.Games

  describe "RoundComponent rendering" do
    setup context do
      num_of_users = context[:user_count] || 3

      create_game(num_of_users)
    end

    test "renders the game container", %{conn: conn, admin: admin, users: [user | _], game: game} do
      {:ok, admin_view, _admin_html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      {:ok, user_view, _user_html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      assert admin_view |> has_element?("#round-container")
      assert user_view |> has_element?("#round-container")
    end

    test "renders which players turn currently", %{
      conn: conn,
      admin: admin,
      users: [user | _],
      game: game
    } do
      {:ok, admin_view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      {:ok, user_view, _user_html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      current_turn_player = current_turn_player(game)

      assert admin_view |> element("#current-turn") |> render() =~
               current_turn_player.display_name

      assert user_view |> element("#current-turn") |> render() =~ current_turn_player.display_name
    end

    test "renders opponents correctly for admin", %{conn: conn, admin: admin, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      %{current_round: %{players: players}} = game

      players
      |> Enum.reject(fn player -> player.user.id == admin.id end)
      |> Enum.each(fn player ->
        assert view |> has_element?("#opponent-#{player.display_name}")
      end)
    end

    test "renders opponents correctly for non admin player", %{
      conn: conn,
      users: [user | _],
      game: game
    } do
      {:ok, view, _user_html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      %{current_round: %{players: players}} = game

      players
      |> Enum.reject(fn player -> player.user.id == user.id end)
      |> Enum.each(fn player ->
        assert view |> has_element?("#opponent-#{player.display_name}")
      end)
    end

    test "renders current player correctly", %{
      conn: conn,
      admin: admin,
      users: [user | _],
      game: game
    } do
      {:ok, admin_view, _admin_html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      {:ok, user_view, _user_html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      assert admin_view |> has_element?("#current-player")
      assert user_view |> has_element?("#current-player")
    end

    test "renders game table", %{conn: conn, admin: admin, users: [user | _], game: game} do
      {:ok, admin_view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      {:ok, user_view, _user_html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      assert admin_view |> has_element?("#game-table")
      assert user_view |> has_element?("#game-table")
    end
  end

  describe "RoundComponent selecting card" do
    setup context do
      num_of_users = context[:user_count] || 3

      create_game(num_of_users)
    end

    test "allows current turn player to select a card", %{conn: conn, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(current_turn_player(game).user)
        |> live(~p"/games/#{game.id}")

      view |> current_player_card_element(2) |> render_click()

      assert_receive {:game_update, _}, 500

      refute view |> current_player_card_element(0) |> card_is_selectable?()
      assert view |> current_player_card_element(1) |> card_is_selectable?()
      assert view |> current_player_card_element(2) |> card_is_selected?()
      assert view |> current_player_card_element(3) |> card_is_selectable?()
      refute view |> current_player_card_element(4) |> card_is_selectable?()
    end

    test "allows non-turn player to select their own cards", %{conn: conn, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(non_turn_player(game).user)
        |> live(~p"/games/#{game.id}")

      view |> current_player_card_element(3) |> render_click()
      assert_receive {:game_update, _}, 500

      assert view |> current_player_card_element(3) |> card_is_selected?()
    end

    test "updates UI correctly when selecting and deselecting cards", %{conn: conn, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(current_turn_player(game).user)
        |> live(~p"/games/#{game.id}")

      view |> current_player_card_element(2) |> render_click()
      assert_receive {:game_update, _}, 500

      assert view |> current_player_card_element(1) |> card_is_selectable?()
      assert view |> current_player_card_element(2) |> card_is_selected?()
      assert view |> current_player_card_element(3) |> card_is_selectable?()

      view |> current_player_card_element(2) |> render_click()
      assert_receive {:game_update, _}, 500

      assert view |> current_player_card_element(0) |> card_is_selectable?()
      assert view |> current_player_card_element(1) |> card_is_selectable?()
      refute view |> current_player_card_element(2) |> card_is_selected?()
      assert view |> current_player_card_element(2) |> card_is_selectable?()
      assert view |> current_player_card_element(3) |> card_is_selectable?()
      assert view |> current_player_card_element(4) |> card_is_selectable?()
    end

    # TODO: simulate error in some other way. We cannot find the element 100th card to assert click on it.
    @tag :skip
    test "handles errors when selecting cards", %{conn: conn, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(current_turn_player(game).user)
        |> live(~p"/games/#{game.id}")

      # Simulate an error (e.g., by trying to select a non-existent card)
      invalid_card_index = 100

      assert view |> element("#current-player-card-#{invalid_card_index}") |> render_click() =~
               "Failed to select card: invalid_index"
    end
  end

  defp current_player_card_element(view, card_index) do
    view |> element("#current-player-card-#{card_index}")
  end

  defp card_is_selectable?(card_element) do
    card_element |> render() =~ "cursor-pointer"
  end

  defp card_is_selected?(card_element) do
    card_element |> render() =~ "ring-2 ring-yellow-400"
  end

  defp create_game(num_of_users) do
    num_of_non_admin_users = num_of_users - 1

    admin = AccountsFixtures.user_fixture(%{email: "admin_user@example.com"})
    users = 1..num_of_non_admin_users |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)

    {:ok, %{id: game_id, pid: _game_pid}} = Games.create_game(admin)

    Phoenix.PubSub.subscribe(Bastrap.PubSub, "game:#{game_id}")

    users
    |> Enum.each(fn user ->
      {:ok, :joining} = Games.join_game(game_id, user)
      assert_receive {:game_update, _}, 500
    end)

    {:ok, :starting} = Games.start_game(game_id, admin)
    assert_receive {:game_update, game}, 500

    %{admin: admin, users: users, game: game}
  end

  defp current_turn_player(
         %{current_round: %{players: players, turn_player_index: turn_player_index}} = _game
       ) do
    Enum.at(players, turn_player_index)
  end

  defp non_turn_player(
         %{current_round: %{players: players, turn_player_index: turn_player_index}} = _game
       ) do
    non_turn_player_index = rem(turn_player_index + 1, length(players))

    players |> Enum.at(non_turn_player_index)
  end
end
