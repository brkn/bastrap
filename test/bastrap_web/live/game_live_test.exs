defmodule BastrapWeb.GameLiveTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.AccountsFixtures

  alias Bastrap.Games

  describe "Game lobby" do
    setup do
      admin = AccountsFixtures.user_fixture(%{email: "admin_email@example.com"})

      users =
        1..2
        |> Enum.map(fn i ->
          AccountsFixtures.user_fixture(%{email: "email#{i}@example.com"})
        end)

      {:ok, game} = Games.create_game(admin)

      Phoenix.PubSub.subscribe(Bastrap.PubSub, "game:#{game.id}")

      %{admin: admin, users: users, game: game}
    end

    test "displays lobby with correct initial state", %{conn: conn, admin: admin, game: game} do
      {:ok, _view, html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      assert html =~ "Game Lobby"
      assert html =~ "Players in lobby: 1"
      assert html =~ admin.email
    end

    test "doesn't show join button for players already in game", %{
      conn: conn,
      admin: admin,
      game: game
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      refute html =~ "Join Game"
    end

    test "allows non-admin user to join the game", %{conn: conn, users: [user | _], game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      view |> element("button", "Join Game") |> render_click()

      assert_receive {:game_update, _}, 500

      assert render(view) =~ "Game Lobby"
      assert render(view) =~ "Players in lobby: 2"
      assert render(view) =~ user.email
    end

    test "updates all connected clients when a new player joins", %{
      conn: conn,
      admin: admin,
      users: [user | _],
      game: game
    } do
      {:ok, admin_view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      {:ok, user_view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      user_view |> element("button", "Join Game") |> render_click()

      assert_receive {:game_update, _}, 500

      assert render(admin_view) =~ "Game Lobby"
      assert render(admin_view) =~ "Players in lobby: 2"
      assert render(admin_view) =~ "admin_email"

      assert render(user_view) =~ "Players in lobby: 2"
      assert render(user_view) =~ "email1"
    end

    test "redirects to home when accessing non-existent game", %{conn: conn, admin: admin} do
      assert {:error, {:live_redirect, %{to: "/"}}} =
               conn
               |> log_in_user(admin)
               |> live(~p"/games/invalid-id")
    end

    test "allows admin to start the game and updates all clients", %{
      conn: conn,
      admin: admin,
      users: users = [_, second_user],
      game: game
    } do
      {:ok, admin_view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/games/#{game.id}")

      {:ok, user_view, _html} =
        conn
        |> log_in_user(second_user)
        |> live(~p"/games/#{game.id}")

      users
      |> Enum.each(fn user ->
        Games.join_game(game.id, user)
        assert_receive {:game_update, _}, 500
      end)

      admin_view |> element("button", "Start Game") |> render_click()

      assert_receive {:game_update, updated_game}, 500
      assert updated_game.state == :in_progress

      assert render(admin_view) =~ "Game in Progress"
      assert render(user_view) =~ "Game in Progress"
    end

    # "Requires mocking the game server to fail"
    @tag :skip
    test "shows error when joining game fails", %{conn: conn, game: game, other_user: other_user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(other_user)
        |> live(~p"/games/#{game.id}")

      # Simulate a failure in join_game
      view |> element("button", "Join Game") |> render_click()
    end
  end
end
