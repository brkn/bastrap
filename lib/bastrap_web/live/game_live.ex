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
    <%= if @game.state == :not_started do %>
      <.live_component
        module={LobbyComponent}
        id={"lobby-#{@current_user.id}"}
        game={@game}
        current_user={@current_user}
      />
    <% else %>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-4 text-center">Game in Progress</h1>
      </div>
    <% end %>
    """
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
end
