defmodule BastrapWeb.Game.OpponentComponent do
  use BastrapWeb, :html

  alias BastrapWeb.Game.CardComponent

  attr :player, Bastrap.Games.Player, required: true
  attr :id, :string, required: true
  attr :rest, :global, default: %{class: "list-none bg-white rounded-lg p-4 shadow"}

  def render(assigns) do
    ~H"""
    <li id={@id} {@rest}>
      <h3
        id={"opponent-display-name-#{@player.display_name}"}
        class="font-semibold text-sm mb-1 truncate"
      >
        <%= @player.display_name %>
      </h3>
      <ol id={"opponent-hand-#{@player.display_name}"} class="flex space-x-0.5">
        <%= for {card, index} <- Enum.with_index(@player.hand.cards) do %>
          <CardComponent.render
            card={card}
            id={"opponent-hand-#{@player.display_name}-card-#{index}"}
          />
        <% end %>
      </ol>
    </li>
    """
  end
end
