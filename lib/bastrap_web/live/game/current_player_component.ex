defmodule BastrapWeb.Game.CurrentPlayerComponent do
  use BastrapWeb, :html

  alias BastrapWeb.Game.CardComponent

  attr :player, Bastrap.Games.Player, required: true
  attr :rest, :global

  # Current player means the player who is on the browser.
  # It's different than the current turn player, which represents the player that has to act in current turn.

  def render(assigns) do
    ~H"""
    <div {@rest} class="flex items-center justify-center">
      <p id="current-player-display-name" class="text-left text-xl font-bold mr-4">
        <%= @player.display_name %>
      </p>
      <ol
        id="current-player-hand"
        class="flex justify-center space-x-1 overflow-x-auto bg-white rounded-lg p-4 shadow"
      >
        <%= for {card, index} <- Enum.with_index(@player.hand.cards) do %>
          <CardComponent.render id={"current-player-card-#{index}"} card={card} />
        <% end %>
      </ol>
    </div>
    """
  end
end
