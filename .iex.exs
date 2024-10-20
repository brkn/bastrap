# .iex.exs

defmodule ConsoleHelpers do
  def populate_game, do: last_game_id() |> populate_game()

  def populate_game(game_id) do
    require Ecto.Query

    query = Ecto.Query.from u in Bastrap.Accounts.User, where: u.email != "asd@asd.asd"

    users = Bastrap.Repo.all query

    users |> Enum.each(fn u -> Bastrap.Games.join_game(game_id, u) end)
  end

  def last_game_id do
    Registry.select(Bastrap.Games.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> List.last()
  end
end
