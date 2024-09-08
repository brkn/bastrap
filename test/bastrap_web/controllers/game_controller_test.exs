defmodule BastrapWeb.GameControllerTest do
  use BastrapWeb.ConnCase, async: true

  alias Bastrap.Games
  import Bastrap.AccountsFixtures

  describe "POST /games" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "creates a game successfully", %{conn: conn, user: user} do
      conn = post(conn, ~p"/games")

      assert %{id: game_id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/games/#{game_id}"

      assert {:ok, game} = Games.get_game(game_id)

      assert game.admin == %Bastrap.Games.Player{user: user, hand: [], display_name: user.email}
      assert game.players |> Enum.map(& &1.user) == [user]
    end
  end

  test "returns error for unauthenticated user", %{conn: conn} do
    conn = post(conn, ~p"/games")
    assert redirected_to(conn) == ~p"/users/log_in"
  end
end
