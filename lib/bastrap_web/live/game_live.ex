defmodule BastrapWeb.GameLive do
  use BastrapWeb, :live_view

  alias Bastrap.Games
  alias BastrapWeb.Game.{LobbyComponent, RoundComponent, ScoringComponent}

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(game_id)

    case Games.get_game(game_id) do
      {:ok, game} -> {:ok, assign(socket, game: game)}
      {:error, _reason} -> {:ok, push_navigate(socket, to: "/")}
    end
  end

  # TODO: use game.id for the components instead of current_user.id
  def render(assigns) do
    ~H"""
    <%= case @game.state do %>
      <% :not_started -> %>
        <.live_component
          module={LobbyComponent}
          id={"lobby-#{@current_user.id}"}
          game={@game}
          current_user={@current_user}
        />
      <% :in_progress -> %>
        <.live_component
          module={RoundComponent}
          id={"game-#{@current_user.id}"}
          round={@game.current_round}
          game_id={@game.id}
          current_user={@current_user}
        />
      <% :scoring -> %>
        <.live_component
          module={ScoringComponent}
          id={"scoring-#{@current_user.id}"}
          game={@game}
          current_user={@current_user}
        />
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

  def handle_info({:game_error, message}, socket) do
    new_socket = socket |> put_flash(:error, message)

    {:noreply, new_socket}
  end

  defp maybe_clear_flash(%{assigns: %{flash: %{info: "Joining game..."}}} = socket) do
    clear_flash(socket, :info)
  end

  defp maybe_clear_flash(socket), do: socket
end
