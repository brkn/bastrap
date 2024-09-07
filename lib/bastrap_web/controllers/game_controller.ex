defmodule BastrapWeb.GameController do
  use BastrapWeb, :controller

  alias Bastrap.Games

  def create(conn, _params) do
    user = conn.assigns.current_user

    case Games.create_game(user) do
      {:ok, game} ->
        conn
        |> redirect(to: ~p"/games/#{game.id}")

      {:error, _reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{game: "Could not create game"}})
    end
  end
end
