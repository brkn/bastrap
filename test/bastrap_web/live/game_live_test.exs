defmodule BastrapWeb.GameLiveTest do
  use BastrapWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Bastrap.Accounts
  alias Bastrap.Games

  describe "Game lobby" do
    setup do
      {:ok, user} = Accounts.register_user(%{email: "test@example.com", password: "password123"})
      {:ok, game} = Games.create_game(user)
      %{user: user, game: game}
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

    @tag :focus
    test "updates when another player joins", %{conn: conn, user: user, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/games/#{game.id}")

      {:ok, other_user} =
        Accounts.register_user(%{email: "other@example.com", password: "password123"})

      Games.join_game(game.id, other_user)

      assert render_async(view) =~ "Game Lobby"
      assert render_async(view) =~ "Players in lobby: 2"
      assert render_async(view) =~ other_user.email
    end
  end
end
