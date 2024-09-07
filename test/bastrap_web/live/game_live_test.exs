defmodule BastrapWeb.GameLiveTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.Accounts
  alias Bastrap.Games

  describe "Game lobby" do
    setup do
      {:ok, user} = Accounts.register_user(%{email: "test@example.com", password: "password123"})

      {:ok, other_user} =
        Accounts.register_user(%{email: "other@example.com", password: "password123"})

      {:ok, game} = Games.create_game(user)

      %{game: game, user: user, other_user: other_user}
    end

    test "displays lobby when accessed", %{conn: conn, user: user, game: game} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      assert html =~ "Game Lobby"
      assert html =~ "Players in lobby: 1"
      assert html =~ user.email
    end

    test "doesn't show join button for players already in game", %{
      conn: conn,
      user: user,
      game: game
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      refute html =~ "Join Game"
    end

    test "updates when another player joins", %{
      conn: conn,
      user: user,
      other_user: other_user,
      game: game
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      Games.join_game(game.id, other_user)

      assert render_async(view) =~ "Game Lobby"
      assert render_async(view) =~ "Players in lobby: 2"
      assert render_async(view) =~ other_user.email
    end

    test "redirects to home when game is not found", %{conn: conn, user: user} do
      assert {:error, {:live_redirect, %{to: "/"}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/games/invalid-id")
    end

    # "TODO: not implemented yet"
    @tag :skip
    test "allows admin to start the game", %{conn: conn, user: user, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      assert view
             |> element("button", "Start Game")
             |> render_click() =~ "Game started"
    end

    # "Requires mocking the game server to fail"
    @tag :skip
    test "shows error when joining game fails", %{conn: conn, game: game, other_user: other_user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(other_user)
        |> live(~p"/games/#{game.id}")

      # Simulate a failure in join_game
      assert view
             |> element("button", "Join Game")
             |> render_click() =~ "Failed to join game"
    end
  end
end
