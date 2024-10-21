defmodule BastrapWeb.Game.CenterPileComponent do
  use BastrapWeb, :html

  alias Bastrap.Games.CenterPile
  alias BastrapWeb.Game.CardComponent

  attr :center_pile, CenterPile, required: true

  attr :class, :string,
    default: "bg-green-600 rounded-lg p-16 flex justify-center items-center space-x-2"

  def render(assigns) do
    ~H"""
    <div id="center-pile" class={@class}>
      <%= for {card, index} <- Enum.with_index(@center_pile.cards) do %>
        <CardComponent.render
          id={"center-pile-card-#{index}"}
          card={card}
          index={index}
          player_id="center_pile"
        />
      <% end %>
    </div>
    """
  end
end
