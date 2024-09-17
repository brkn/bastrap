defmodule BastrapWeb.Game.OpponentComponent do
  use BastrapWeb, :html

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
        <%= for {_, i} <- Enum.with_index(@player.hand) do %>
          <li
            id={"opponent-hand-#{@player.display_name}-card-#{i}"}
            class="flex-shrink-0 w-6 h-8 bg-blue-500 rounded-sm shadow"
          >
          </li>
        <% end %>
      </ol>
    </li>
    """
  end
end
