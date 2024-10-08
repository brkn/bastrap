defmodule BastrapWeb.Game.CurrentPlayerComponent do
  use BastrapWeb, :html

  attr :player, Bastrap.Games.Player, required: true
  attr :rest, :global

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
        <%= for {{left, right}, index} <- Enum.with_index(@player.hand) do %>
          <li
            id={"player-card-#{index}"}
            class="flex-shrink-0 w-10 h-14 bg-red-600 border border-black rounded-md relative shadow"
          >
            <p class="absolute top-0 left-0.5 text-xs font-bold text-white"><%= left %></p>
            <p class="absolute bottom-0 right-0.5 text-xs font-bold text-white"><%= right %></p>
          </li>
        <% end %>
      </ol>
    </div>
    """
  end
end
