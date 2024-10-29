defmodule BastrapWeb.Game.RoundComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bastrap.AccountsFixtures
  alias Bastrap.Games
  alias Bastrap.Games.Hand

  alias Bastrap.GameFixtures

  alias Bastrap.GameFixtures

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

      assert admin_view |> has_element?("#center-pile")
      assert user_view |> has_element?("#center-pile")
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

    test "allows current turn player to submit valid card set", %{conn: conn, game: game} do
      {:ok, view, _html} =
        conn
        |> log_in_user(current_turn_player(game).user)
        |> live(~p"/games/#{game.id}")

      current_player_hand_count =
        view |> element("#current-player-hand") |> render() |> count_cards()

      # Center is empty, any single selected card is valid and higher then center pile.
      view |> current_player_card_element(0) |> render_click()
      assert_receive {:game_update, _}, 500

      # Submit the selected cards
      view |> element("#submit-selected-cards-button") |> render_click()
      assert_receive {:game_update, updated_game}, 500

      # Validate state changes
      assert updated_game.current_round.turn_player_index != game.current_round.turn_player_index

      updated_current_player_hand_count =
        view |> element("#current-player-hand") |> render() |> count_cards()

      assert updated_current_player_hand_count == current_player_hand_count - 1
    end

    @tag :flaky
    test "shows error when submitting invalid card set", %{conn: conn, game: game} do
      game =
        game
        |> GameFixtures.with_center_pile([{5, 6}, {5, 7}])
        |> Games.put_game()

      {:ok, view, _html} =
        conn
        |> log_in_user(current_turn_player(game).user)
        |> live(~p"/games/#{game.id}")

      current_player_hand_count =
        view |> element("#current-player-hand") |> render() |> count_cards()

      # Single card can never beat the center pair
      view |> current_player_card_element(0) |> render_click()
      assert_receive {:game_update, _}, 500

      # Try to submit invalid set
      view |> element("#submit-selected-cards-button") |> render_click()
      assert_receive {:game_error, "Selected cards must be higher than center pile"}, 500

      updated_current_player_hand_count =
        view |> element("#current-player-hand") |> render() |> count_cards()

      assert current_player_hand_count == updated_current_player_hand_count
    end

    test "prevents non-turn player from submitting cards", %{conn: conn, game: game} do
      non_turn_player =
        game.current_round.players
        |> Enum.reject(&(&1.user.id == current_turn_player(game).user.id))
        |> List.first()

      {:ok, view, _html} =
        conn
        |> log_in_user(non_turn_player.user)
        |> live(~p"/games/#{game.id}")

      view |> current_player_card_element(0) |> render_click()
      assert_receive {:game_update, _}, 500

      view |> element("#submit-selected-cards-button") |> render_click()
      assert_receive {:game_error, "Not your turn"}, 500
    end

    test "ends round when a player empties their hand", %{
      conn: conn,
      game: %{current_round: %{turn_player_index: turn_player_index}} = game
    } do
      mocked_game =
        game
        |> GameFixtures.update_player(turn_player_index, fn player ->
          %{player | hand: Hand.new([{9, 10}])}
        end)
        |> Games.put_game()

      # assert_receive {:game_update, mocked_game}, 500

      {:ok, view, _html} =
        conn
        |> log_in_user(current_turn_player(mocked_game).user)
        |> live(~p"/games/#{game.id}")

      view |> current_player_card_element(0) |> render_click()
      assert_receive {:game_update, _}, 500

      view |> element("#submit-selected-cards-button") |> render_click()
      assert_receive {:game_update, updated_game}, 500

      assert updated_game.state == :scoring
    end
  end

  # TODO: Add test case - Assert the current turn player is indicated on screen.

  describe "player visibility" do
    # TODO: Add test case - Assert exact number of face-down cards for opponents

    setup context do
      # TODO: context[:user_count] feels awkward - Try using pattern matching in setup's params instead
      num_of_users = context[:user_count] || 3

      %{users: [opponent | _], game: game} = create_game(num_of_users)

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(opponent)
        |> live(~p"/games/#{game.id}")

      %{view: view}
    end

    test "renders opponent cards as face down", %{view: view} do
      opponent_hand = view |> element("#opponent-hand-player-2") |> render()

      refute opponent_hand =~ ~r{<p[^>]*>\s*\d+\s*</p>}
      assert opponent_hand =~ ~r{class="[^"]*bg-blue-500[^"]*"}
    end

    test "opponent cards are not selectable", %{view: view} do
      opponent_hand = view |> element("#opponent-hand-player-2") |> render()

      refute opponent_hand =~ ~r{cursor-pointer}
      refute opponent_hand =~ ~r{phx-click="select_card"}
    end

    test "current player can see their own cards", %{view: view} do
      current_player_hand = view |> element("#current-player-hand") |> render()

      assert current_player_hand =~ ~r{<p[^>]*>\s*\d+\s*</p>}
      refute current_player_hand =~ ~r{bg-blue-500}
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

  # TODO:
  # 1. Move this to a fixture module or something/
  # 2. Has multiple responsibilities. Could be split into smaller functions
  defp create_game(num_of_users) do
    num_of_non_admin_users = num_of_users - 1

    admin = AccountsFixtures.user_fixture(%{email: "admin_user@example.com"})

    users =
      1..num_of_non_admin_users
      |> Enum.map(fn index ->
        AccountsFixtures.user_fixture(%{email: "player-#{index}@example.com"})
      end)

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

  defp count_cards(html) do
    Regex.scan(~r{<li[^>]*id="current-player-card-\d+"[^>]*>}, html) |> length()
  end
end
