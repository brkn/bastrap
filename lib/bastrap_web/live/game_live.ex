defmodule BastrapWeb.GameLive do
  use BastrapWeb, :live_view
  alias Bastrap.Games

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(game_id)

    case Games.get_game(game_id) do
      {:ok, game} -> {:ok, assign(socket, game: game)}
      {:error, _reason} -> {:ok, push_navigate(socket, to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-4 text-center">Game Lobby</h1>
      <p class="text-lg text-gray-700 mb-4 text-center">
        Players in lobby: <%= length(@game.players) %>
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <%= for player <- @game.players do %>
          <div class="bg-white shadow-md rounded-lg p-4 flex items-center justify-between">
            <p class="text-xl font-medium"><%= player.email %></p>
            <%= if player == @game.admin do %>
              <span class="ml-auto text-yellow-500">⭐ Admin</span>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @current_user == @game.admin do %>
        <div class="mt-8 text-center">
          <button
            phx-click="start_game"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Start Game
          </button>
        </div>
      <% end %>

      <%= if not user_in_game?(@game, @current_user) do %>
        <div class="mt-8 text-center">
          <button
            phx-click="join_game"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Join Game
          </button>
        </div>
      <% end %>
    </div>
    """
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

  def handle_info({:game_update, updated_game}, socket) do
    new_socket =
      socket
      |> assign(game: updated_game)
      |> maybe_clear_flash()

    {:noreply, new_socket}
  end

  defp maybe_clear_flash(%{assigns: %{flash: %{info: "Joining game..."}}} = socket) do
    clear_flash(socket, :info)
  end

  defp maybe_clear_flash(socket), do: socket

  defp user_in_game?(game, user), do: Enum.member?(game.players, user)
end
