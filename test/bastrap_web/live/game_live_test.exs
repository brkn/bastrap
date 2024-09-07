defmodule BastrapWeb.GameLiveTest do
  use BastrapWeb.ConnCase

  # import Phoenix.LiveViewTest
  alias Bastrap.Accounts
  alias Bastrap.Games

  # TODO: fix this after the games context tests are done
  @moduletag :skip

  describe "Game lobby" do
    setup do
      {:ok, user} = Accounts.register_user(%{email: "test@example.com", password: "password123"})
      {:ok, game} = Games.create_game(user)
      %{user: user, game: game}
    end

    test "displays lobby when accessed", %{conn: conn, user: user, game: _game} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        # |> live(~p"/game/#{game.id}")

      assert html =~ "Game Lobby"
      assert html =~ "Players in lobby: 1"
      assert html =~ user.email
    end

    test "updates when another player joins", %{conn: conn, user: user, game: _game} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        # |> live(~p"/game/#{game.id}")

      {:ok, other_user} =
        Accounts.register_user(%{email: "other@example.com", password: "password123"})

      # Games.join_game(game.id, other_user.id)

      assert html =~ "Game Lobby"
      assert html =~ "Players in lobby: 2"
      assert html =~ other_user.email
    end
  end
end
