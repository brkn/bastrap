defmodule Bastrap.GameFixtures do
  alias Bastrap.Games.{Game, CenterPile}
  alias Bastrap.AccountsFixtures
  alias Phoenix.PubSub

  def new(opts \\ []) do
    admin = opts[:admin] || AccountsFixtures.user_fixture()
    id = opts[:id] || Ecto.UUID.generate()

    Game.new(id, admin)
  end

  def start_game(game, opts \\ []) do
    game
    |> add_players(opts[:player_count])
    |> Game.start(game.admin.user)
    |> then(fn {:ok, started_game} ->
      started_game
      |> maybe_set_dealer_index(opts[:dealer_index])
      |> maybe_set_turn_index(opts[:turn_player_index])
    end)
  end

  def with_center_pile(game, ranks) when is_list(ranks) do
    put_in(game.current_round.center_pile, CenterPile.new(ranks))
  end

  def update_player(game, player_index, update_fn)
      when is_integer(player_index) and is_function(update_fn, 1) do
    put_in(
      game.current_round.players,
      List.update_at(game.current_round.players, player_index, update_fn)
    )
  end

  def subscribe(game) do
    :ok = PubSub.subscribe(Bastrap.PubSub, "game:#{game.id}")
    game
  end

  defp maybe_set_dealer_index(game, nil), do: game

  defp maybe_set_dealer_index(game, index) do
    put_in(game.current_round.dealer_index, index)
  end

  defp maybe_set_turn_index(game, nil), do: game

  defp maybe_set_turn_index(game, index) do
    put_in(game.current_round.turn_player_index, index)
  end

  defp add_players(game, nil), do: add_players(game, 3)

  defp add_players(game, count) do
    1..count
    |> Enum.map(fn _ -> AccountsFixtures.user_fixture() end)
    |> Enum.reduce(game, fn user, game ->
      {:ok, game} = Game.join(game, user)
      game
    end)
  end
end
