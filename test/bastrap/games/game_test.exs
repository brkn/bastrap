defmodule Bastrap.Games.GameTest do
  use Bastrap.DataCase, async: true

  alias Bastrap.Games.Game
  alias Bastrap.Games.Player
  alias Bastrap.AccountsFixtures
  alias Bastrap.GameFixtures

  doctest Bastrap.Games.Game

  describe "new/2" do
    setup do
      admin = AccountsFixtures.user_fixture()
      %{admin: admin}
    end

    test "creates a game with the given admin", %{admin: admin} do
      game = Game.new("game-123", admin)

      assert game.id == "game-123"
      assert game.state == :not_started
      assert game.admin.user == admin
      assert [%Player{user: ^admin}] = game.players
      assert game.current_round == nil
    end
  end

  describe "join/2" do
    setup do
      admin = AccountsFixtures.user_fixture()
      game = Game.new("game-123", admin)
      user = AccountsFixtures.user_fixture()
      %{game: game, user: user}
    end

    test "adds player to the game", %{game: game, user: user} do
      {:ok, updated_game} = Game.join(game, user)

      assert length(updated_game.players) == 2
      assert Enum.any?(updated_game.players, &(&1.user.id == user.id))
    end

    test "prevents joining when game has already started", %{game: game, user: user} do
      game = %{game | state: :in_progress}
      assert {:error, :game_already_started} = Game.join(game, user)
    end

    test "ignores duplicate join calls for the same user", %{game: game, user: user} do
      {:ok, game_with_user} = Game.join(game, user)
      {:ok, game_after_rejoin} = Game.join(game_with_user, user)

      assert game_with_user == game_after_rejoin
    end
  end

  describe "start/2" do
    setup do
      admin = AccountsFixtures.user_fixture()
      game = Game.new("game-123", admin)
      %{game: game, admin: admin}
    end

    test "starts the game when conditions are met", %{game: game, admin: admin} do
      users = Enum.map(1..2, fn _ -> AccountsFixtures.user_fixture() end)

      game =
        Enum.reduce(users, game, fn user, acc ->
          {:ok, game} = Game.join(acc, user)
          game
        end)

      {:ok, started_game} = Game.start(game, admin)

      assert started_game.state == :in_progress
      assert started_game.current_round != nil
      assert length(started_game.current_round.players) == 3
    end

    test "only admin can start the game", %{game: game} do
      game =
        1..3
        |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)
        |> Enum.reduce(game, fn user, acc ->
          {:ok, updated_game} = Game.join(acc, user)
          updated_game
        end)

      non_admin_player = game.players |> List.last()

      assert {:error, :not_admin} = Game.start(game, non_admin_player)
    end

    test "requires minimum 3 players", %{game: game, admin: admin} do
      user = AccountsFixtures.user_fixture()
      {:ok, game} = Game.join(game, user)

      assert {:error, :not_enough_players} = Game.start(game, admin)
    end

    test "prevents more than 5 players", %{game: game, admin: admin} do
      game =
        1..5
        |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)
        |> Enum.reduce(game, fn user, acc ->
          {:ok, updated_game} = Game.join(acc, user)
          updated_game
        end)

      assert {:error, :too_many_players} = Game.start(game, admin)
    end
  end

  describe "select_card/2" do
    setup do
      game = create_started_game_with_players(3)
      %{game: game}
    end

    test "selects a valid card in the player's hand", %{game: game} do
      player_index = 2
      card_index = 3
      player_id = Enum.at(game.current_round.players, player_index).user.id
      card_position = %{card_index: card_index, player_id: player_id}

      {:ok, updated_game} = Game.select_card(game, card_position)

      selected_card =
        updated_game.current_round.players
        |> Enum.at(player_index)
        |> then(& &1.hand.cards)
        |> Enum.at(card_index)

      assert %Bastrap.Games.Hand.Card{selected: true, selectable: true} = selected_card
    end

    test "returns error for invalid card index", %{game: game} do
      card_position = %{
        card_index: 999,
        player_id: Enum.at(game.current_round.players, 0).user.id
      }

      assert {:error, :invalid_index} = Game.select_card(game, card_position)
    end

    test "returns error for non-existent player", %{game: game} do
      card_position = %{card_index: 0, player_id: -1}

      assert {:error, :player_not_found} = Game.select_card(game, card_position)
    end

    test "returns error when game hasn't started", %{game: game} do
      card_position = %{card_index: 0, player_id: Enum.at(game.players, 0).user.id}
      game = %{game | state: :not_started}

      assert {:error, :invalid_game_state} = Game.select_card(game, card_position)
    end

    test "selects and deselects card when called multiple times", %{game: game} do
      player = Enum.at(game.current_round.players, 0)
      card_position = %{card_index: 0, player_id: player.user.id}

      {:ok, game_selected} = Game.select_card(game, card_position)

      assert %Bastrap.Games.Hand.Card{selected: true} =
               game_selected.current_round.players
               |> Enum.at(0)
               |> then(& &1.hand.cards)
               |> Enum.at(0)

      {:ok, game_deselected} = Game.select_card(game_selected, card_position)

      refute %Bastrap.Games.Hand.Card{selected: true} ==
               game_deselected.current_round.players
               |> Enum.at(0)
               |> then(& &1.hand.cards)
               |> Enum.at(0)
    end
  end

  describe "submit_selected_cards/1" do
    setup do
      game =
        GameFixtures.new()
        |> GameFixtures.start_game(player_count: 3, turn_player_index: 0)
        |> GameFixtures.subscribe()

      %{game: game}
    end

    test "submits cards and passes turn", %{game: game} do
      game =
        game
        |> GameFixtures.update_player(0, fn player ->
          player.hand.cards
          |> List.update_at(0, &%{&1 | selected: true})
          |> then(&%{player | hand: %{player.hand | cards: &1}})
        end)

      {:ok, updated_game, _score} = Game.submit_selected_cards(game)

      assert updated_game.current_round.turn_player_index == 1
    end

    test "increases the player score when beating center pile cards", %{game: game} do
      game =
        game
        |> GameFixtures.with_center_pile([{1, 2}])
        |> GameFixtures.update_player(0, fn player ->
          player.hand.cards
          |> List.update_at(0, &%{&1 | selected: true, ranks: {2, 3}})
          |> then(&%{player | hand: %{player.hand | cards: &1}})
        end)

      {:ok, updated_game, score} = Game.submit_selected_cards(game)
      assert 1 == score
      assert 1 == updated_game.current_round.players |> hd() |> then(& &1.current_score)
    end

    test "returns error when submitting invalid card set", %{game: game} do
      game =
        GameFixtures.update_player(game, 0, fn player ->
          update_in(player.hand.cards, fn cards ->
            cards
            |> List.update_at(0, &%{&1 | selected: true, ranks: {1, 2}})
            |> List.update_at(2, &%{&1 | selected: true, ranks: {5, 6}})
          end)
        end)

      assert {:error, :card_set_not_higher} = Game.submit_selected_cards(game)
    end

    test "returns error when no cards selected", %{game: game} do
      assert {:error, :card_set_not_higher} = Game.submit_selected_cards(game)
    end
  end

  describe "start_next_round/2" do
    setup do
      game =
        GameFixtures.new()
        |> GameFixtures.start_game(player_count: 3, dealer_index: 3)
        |> Map.put(:state, :scoring)

      non_admin_user = game.players |> List.last() |> then(& &1.user)

      %{game: game, admin_user: game.admin.user, non_admin_user: non_admin_user}
    end

    test "only admin can start next round", %{game: game, non_admin_user: non_admin_user} do
      assert {:error, :not_admin} = Game.start_next_round(game, non_admin_user)
    end

    test "can only start next round in scoring state", %{game: game, admin_user: admin_user} do
      game = %{game | state: :in_progress}

      assert {:error, :invalid_state_transition} = Game.start_next_round(game, admin_user)
    end

    test "rotates dealer to next player", %{game: game, admin_user: admin_user} do
      {:ok, new_game} = Game.start_next_round(game, admin_user)

      assert new_game.current_round.dealer_index == 0
    end

    test "keeps game state consistent between rounds", %{game: game, admin_user: admin_user} do
      {:ok, new_game} = Game.start_next_round(game, admin_user)

      assert new_game.state == :in_progress
      assert new_game.admin == game.admin
      assert length(new_game.current_round.players) == 4
      assert same_order_of_players?(game.players, new_game.current_round.players)
    end
  end

  defp same_order_of_players?(players, new_round_players) do
    Enum.map(new_round_players, & &1.user.id) == Enum.map(players, & &1.user.id)
  end

  defp create_started_game_with_players(count) do
    admin = AccountsFixtures.user_fixture()
    game = Game.new("game-123", admin)

    1..(count - 1)
    |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)
    |> Enum.reduce(game, fn user, acc ->
      {:ok, updated_game} = Game.join(acc, user)
      updated_game
    end)
    |> then(fn game ->
      {:ok, started_game} = Game.start(game, admin)
      started_game
    end)
  end
end
