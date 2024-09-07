defmodule BastrapWeb.GameLive do
  use BastrapWeb, :live_view
  alias Bastrap.Games

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(game_id)

    case Games.get_game(game_id) do
      {:ok, game} ->
        {:ok, assign(socket, game: game)}

      {:error, _reason} ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  def handle_info({:game_update, updated_game}, socket) do
    {:noreply, assign(socket, game: updated_game)}
  end
end
