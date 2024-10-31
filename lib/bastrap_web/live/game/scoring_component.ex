defmodule BastrapWeb.Game.ScoringComponent do
  use BastrapWeb, :live_component

  def render(assigns) do
    ~H"""
    <section id="scoring-container" class="container mx-auto p-4">
      <h2 id="round-winner" class="text-3xl font-bold text-center mb-8">
        <%= @game.admin.display_name %> won the round!
      </h2>

      <ul class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <%= for player <- @game.current_round.players do %>
          <li class="bg-white p-6 rounded-lg shadow-md">
            <h3 class="text-xl font-semibold mb-4"><%= player.display_name %></h3>
            <p id={"player-score-#{player.user.id}"} class="text-2xl mb-2">
              <%= player.current_score %>
            </p>
            <p class="text-sm text-gray-600">
              Remaining cards: <%= length(player.hand.cards) %>
              <%= if length(player.hand.cards) > 0 do %>
                <span class="text-red-500 block">-<%= length(player.hand.cards) %> points</span>
              <% end %>
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
      <% end %>
    </section>
    """
  end
end
