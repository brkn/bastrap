defmodule BastrapWeb.Game.CenterPileComponent do
  use BastrapWeb, :live_component

  alias BastrapWeb.Game.CenterPileCardComponent

  def render(assigns) do
    ~H"""
    <div id="center-pile" class="bg-green-600 rounded-lg p-4 flex flex-col items-center space-y-4">
      <div class="flex justify-center items-center space-x-2">
        <%= for {card, index} <- Enum.with_index(@center_pile.cards) do %>
          <CenterPileCardComponent.render id={"center-pile-card-#{index}"} card={card} index={index} />
        <% end %>
      </div>
    </div>
    """
  end
end
