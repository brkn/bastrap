defmodule BastrapWeb.Game.CenterPileComponent do
  use BastrapWeb, :live_component

  alias BastrapWeb.Game.CenterPileCardComponent

  def render(assigns) do
    ~H"""
    <div
      id="center-pile"
      class="flex flex-col w-full h-full items-center space-y-4 bg-green-600 rounded-lg p-4"
      style="grid-area: game;"
    >
      <ol class="flex justify-center items-center space-x-2">
        <%= for {card, index} <- Enum.with_index(@center_pile.cards) do %>
          <CenterPileCardComponent.render id={"center-pile-card-#{index}"} card={card} index={index} />
        <% end %>
      </ol>
    </div>
    """
  end
end
