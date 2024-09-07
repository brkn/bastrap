defmodule BastrapWeb.HomeControllerTest do
  use BastrapWeb.ConnCase, async: true

  import Bastrap.AccountsFixtures

  describe "GET /" do
    test "renders welcome message", %{conn: conn} do
      conn = get(conn, ~p"/")

      response = html_response(conn, 200)

      assert response =~ "Welcome to Bastrap"
    end

    test "renders register and login links when not logged in", %{conn: conn} do
      conn = get(conn, ~p"/")

      response = html_response(conn, 200)

      assert response =~ "Register"
      assert response =~ ~p"/users/register"
      assert response =~ "Login"
      assert response =~ ~p"/users/log_in"
      refute response =~ "Create Game"
    end

    test "renders join game link when logged in", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get(~p"/")

      response = html_response(conn, 200)

      assert response =~ "Create Game"
      # assert response =~ ~p"/game"
      refute response =~ "Register"
      refute response =~ "Login"
    end
  end
end
