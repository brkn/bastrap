defmodule BastrapWeb.Game.CardComponent do
  use BastrapWeb, :html

  alias Bastrap.Games.Hand.Card, as: HandCard

  attr :card, HandCard, required: true
  attr :id, :string, required: true
  attr :rest, :global

  def render(assigns) do
    assigns =
      assigns
      |> assign(:face_down, HandCard.face_down?(assigns.card))
      |> assign(:background_color, background_color(assigns.card))
      |> assign(:ranks, card_ranks(assigns.card))

    ~H"""
    <li
      id={@id}
      {@rest}
      class={[
        "flex-shrink-0 w-10 h-14 rounded-md relative shadow",
        @background_color,
        @card.selected && "ring-2 ring-yellow-400",
        @card.selectable && "cursor-pointer hover:ring-2 hover:ring-green-400"
      ]}
    >
      <%= if !@face_down do %>
        <p class="absolute top-0 left-0.5 text-xs font-bold text-white">
          <%= elem(@ranks, 0) %>
        </p>
        <p class="absolute bottom-0 right-0.5 text-xs font-bold text-white">
          <%= elem(@ranks, 1) %>
        </p>
      <% end %>
    </li>
    """
  end

  defp background_color(card) do
    if HandCard.face_down?(card) do
      "bg-blue-500"
    else
      "bg-red-600 border border-black"
    end
  end

  defp card_ranks(%HandCard{ranks: :face_down}), do: {nil, nil}
  defp card_ranks(%HandCard{ranks: ranks}), do: ranks
end
