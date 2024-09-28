defmodule BastrapWeb.Game.RoundComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.AccountsFixtures
  alias Bastrap.Games

  describe "RoundComponent" do
    setup context do
      num_of_user = context[:user_count] || 3

      admin = AccountsFixtures.user_fixture(%{email: "admin_user@example.com"})
      users = 1..num_of_user |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)

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

      %{current_round: %{players: players, current_player_index: current_player_index}} = game
      current_turn_player = Enum.at(players, current_player_index)

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

      assert admin_view |> has_element?("#current-player-#{display_name(admin)}")
      assert user_view |> has_element?("#current-player-#{display_name(user)}")
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

  defp display_name(user) do
    Bastrap.Games.Player.new(user).display_name
  end
end
