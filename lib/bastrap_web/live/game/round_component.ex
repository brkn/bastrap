defmodule BastrapWeb.Game.RoundComponent do
  use BastrapWeb, :live_component

  alias BastrapWeb.Game.{OpponentComponent, CurrentPlayerComponent}
  alias Bastrap.Games

  def render(assigns) do
    %{
      round: %{players: players, turn_player_index: turn_player_index},
      current_user: current_user
    } = assigns

    {current_player, other_players} = partition_players(players, current_user)

    assigns =
      assign(
        assigns,
        current_player: current_player,
        other_players: other_players,
        current_turn_player: Enum.at(players, turn_player_index)
      )

    ~H"""
    <section id="round-container" class="container h-full min-w-min mx-auto">
      <h2 id="current-turn" class="bg-green-100 rounded-lg p-4 mb-4 text-xl font-bold text-center">
        Current Turn: <%= @current_turn_player.display_name %>
      </h2>

      <div
        id="game-grid"
        class="grid grid-cols-[420px_auto_420px] grid-rows-2 place-items-center gap-2 mb-2 h-4/5"
        style="grid-template-areas:
        'opp1 game opp2'
        'opp3 game opp4';"
      >
        <%= for player <- @other_players do %>
          <OpponentComponent.render id={"opponent-#{player.display_name}"} player={player} />
        <% end %>

        <div
          id="game-table"
          class="bg-green-600 rounded-lg p-16 flex items-center justify-center text-white text-2xl font-bold"
          style="grid-area: game;"
        >
          Game Table
        </div>
      </div>

      <CurrentPlayerComponent.render id="current-player" player={@current_player} />
    </section>
    """
  end

  def handle_event("select_card", %{"index" => card_index, "player-id" => player_id}, socket) do
    %{game_id: game_id, current_user: current_user} = socket.assigns

    player_card_id = %{
      card_index: String.to_integer(card_index),
      player_id: String.to_integer(player_id)
    }

    case Games.select_card(game_id, current_user, player_card_id) do
      {:ok, :selecting_card} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to select card: #{reason}")}
    end
  end

  defp partition_players(players, current_user) do
    {[current_player], other_players} =
      players |> Enum.split_with(&(&1.user.id == current_user.id))

    {current_player, other_players}
  end
end
