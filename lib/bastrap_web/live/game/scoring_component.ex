defmodule BastrapWeb.Game.ScoringComponent do
  use BastrapWeb, :live_component

  alias Bastrap.Games

  def mount(socket) do
    {:ok, assign(socket, :total_scores, %{})}
  end

  def update(assigns, socket) do
    total_scores =
      assigns.game.players
      |> Enum.map(fn p -> {p.user.id, p.current_score} end)
      |> Map.new()

    {:ok, assign(socket, assigns) |> assign(:total_scores, total_scores)}
  end

  def render(assigns) do
    ~H"""
    <section id="scoring-container" class="container mx-auto p-4">
      <ul class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <%= for player <- @game.current_round.players do %>
          <li class={[
            "bg-white p-6 rounded-lg shadow-md",
            player.hand.cards == [] && "ring-2 ring-yellow-400"
          ]}>
            <h3 class="text-xl font-semibold mb-4 flex items-center gap-2">
              <%= player.display_name %>
              <%= if player.hand.cards == [] do %>
                <span class="text-yellow-500 text-sm">🎉 Round Winner</span>
              <% end %>
            </h3>

            <dl class="space-y-2 mb-4">
              <dt class="flex justify-between">
                Started with
                <span id={"player-#{player.display_name}-starting-score"}>
                  <%= Map.get(@total_scores, player.user.id, 0) %>
                </span>
              </dt>

              <dt class="flex justify-between">
                Points earned
                <span id={"player-#{player.display_name}-round-score"} class="text-green-600">
                  +<%= player.current_score %>
                </span>
              </dt>

              <dt class="flex justify-between">
                Cards left
                <span id={"player-#{player.display_name}-penalty-score"} class="text-red-600">
                  <%= if length(player.hand.cards) > 0 do %>
                    -<%= length(player.hand.cards) %>
                  <% else %>
                    0
                  <% end %>
                </span>
              </dt>
            </dl>

            <p class="pt-4 border-t text-lg font-medium flex justify-between">
              Total
              <span id={"player-#{player.display_name}-total-score"}>
                <%= calculate_total(player, @total_scores) %>
              </span>
            </p>
          </li>
        <% end %>
      </ul>

      <%= if @current_user.id == @game.admin.user.id do %>
        <button
          phx-click="start_next_round"
          phx-target={@myself}
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mx-auto block"
        >
          Start Next Round
        </button>
      <% else %>
        <p id="waiting-message">
          Waiting for game admin to start next round
        </p>
      <% end %>
    </section>
    """
  end

  def handle_event("start_next_round", _, socket) do
    %{game: %{id: game_id}, current_user: current_user} = socket.assigns

    case Games.start_next_round(game_id, current_user) do
      {:ok, :starting} ->
        {:noreply, put_flash(socket, :info, "Starting next round...")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start next round: #{reason}")}
    end

    {:noreply, socket}
  end

  defp calculate_total(player, total_scores) do
    Map.get(total_scores, player.user.id, 0) + player.current_score - length(player.hand.cards)
  end
end
