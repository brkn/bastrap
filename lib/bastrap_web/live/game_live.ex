defmodule BastrapWeb.GameLive do
  use BastrapWeb, :live_view

  alias Bastrap.Games
  alias BastrapWeb.Game.LobbyComponent

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(game_id)

    case Games.get_game(game_id) do
      {:ok, game} -> {:ok, assign(socket, game: game)}
      {:error, _reason} -> {:ok, push_navigate(socket, to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <.live_component module={LobbyComponent} id="lobby" game={@game} current_user={@current_user} />
    """
  end

  def handle_info({:game_update, updated_game}, socket) do
    new_socket =
      socket
      |> assign(game: updated_game)
      |> maybe_clear_flash()

    {:noreply, new_socket}
  end

  def handle_event("join_game", _, socket) do
    %{game: game, current_user: current_user} = socket.assigns

    case Games.join_game(game.id, current_user) do
      {:ok, :joining} ->
        {:noreply, put_flash(socket, :info, "Joining game...")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to join game: #{reason}")}
    end
  end

  def handle_event("start_game", _, socket) do
    %{game: %{id: game_id}, current_user: current_user} = socket.assigns

    Games.start_game(game_id, current_user)

    {:noreply, socket}
  end

  defp maybe_clear_flash(%{assigns: %{flash: %{info: "Joining game..."}}} = socket) do
    clear_flash(socket, :info)
  end

  defp maybe_clear_flash(socket), do: socket
end
