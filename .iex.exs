# .iex.exs

defmodule ConsoleHelpers do
  @moduledoc """
  Helper functions for interacting with Bastrap game state in IEx console.
  Provides utilities for creating test games, populating with users, and setting up demo scenarios.
  """

  require Ecto.Query

  alias Bastrap.{Games, Repo}
  alias Bastrap.Games.{Hand, CenterPile}
  alias Bastrap.Accounts.User

  @admin_player_mail "asd@asd.asd"

  @doc """
  Populates the most recently created game with all test users.
  """
  def populate_game, do: last_game_id() |> populate_game()

  @doc """
  Populates the specified game with all available test users.
  Excludes the admin user.
  """
  def populate_game(game_id) do
    Ecto.Query.from(u in User, where: u.email != @admin_player_mail)
    |> Repo.all()
    |> Enum.each(&Games.join_game(game_id, &1))

    game_id
  end

  @doc """
  Sets up a game state where the admin is about to win the round.
  The admin will have a winning hand, others will have random scores and hands.
  """
  def round_almost_done_demo(game_id) do
    game = get_game(game_id)

    admin_index =
      Enum.find_index(game.current_round.players, &(&1.user.email == @admin_player_mail))

    game
    |> put_in([Access.key(:current_round), Access.key(:turn_player_index)], admin_index)
    |> then(fn game ->
      game.current_round.players
      |> Enum.with_index()
      |> Enum.map(fn
        {player, ^admin_index} ->
          %{player | hand: Hand.new([{9, 10}, {9, 4}]), current_score: Enum.random(1..10)}

        {player, _index} ->
          %{player | current_score: Enum.random(-5..11)}
      end)
      |> then(&put_in(game.current_round.players, &1))
    end)
    |> then(fn game ->
      %{
        game
        | current_round: %{
            game.current_round
            | center_pile: CenterPile.new([{1, 2}, {1, 3}])
          }
      }
    end)
    |> Games.put_game()
  end

  @doc """
  Returns the ID of the most recently created game.
  """
  def last_game_id do
    Registry.select(Bastrap.Games.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> List.last()
  end

  defp get_game(game_id) do
    case Games.get_game(game_id) do
      {:ok, game} -> game
      {:error, _} -> raise "Game not found: #{game_id}"
    end
  end
end
