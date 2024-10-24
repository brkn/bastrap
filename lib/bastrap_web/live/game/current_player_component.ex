defmodule BastrapWeb.Game.CurrentPlayerComponent do
  @moduledoc """
  Renders the section for the current player viewing the game.
  Unlike the turn player which indicates who should play next,
  this component shows cards and actions for the player using the browser.
  """

  use BastrapWeb, :html

  alias BastrapWeb.Game.CardComponent

  attr :player, Bastrap.Games.Player, required: true
  attr :rest, :global

  # Current player means the player who is on the browser.
  # It's different than the current turn player, which represents the player that has to act in current turn.

  def render(%{player: player} = assigns) do
    has_selected_cards = has_selected_cards?(player)

    assigns =
      assigns
      |> assign(:has_selected_cards?, has_selected_cards)
      |> assign(
        :submit_selected_cards_button_styling,
        submit_selected_cards_button_styling(has_selected_cards)
      )

    ~H"""
    <div {@rest} class="flex flex-col items-center justify-center space-y-4">
      <p id="current-player-display-name" class="text-left text-xl font-bold">
        <%= @player.display_name %>
      </p>
      <ol
        id="current-player-hand"
        class="flex justify-center space-x-1 overflow-x-auto bg-white rounded-lg p-4 shadow"
      >
        <%= for {card, index} <- Enum.with_index(@player.hand.cards) do %>
          <CardComponent.render
            id={"current-player-card-#{index}"}
            card={card}
            index={index}
            player_id={@player.user.id}
          />
        <% end %>
      </ol>
      <button
        id="submit-selected-cards-button"
        phx-click="submit_turn"
        phx-target="#round-container"
        disabled={!@has_selected_cards?}
        class={@submit_selected_cards_button_styling}
      >
        Submit
      </button>
    </div>
    """
  end

  defp has_selected_cards?(player) do
    player.hand.cards |> Enum.any?(& &1.selected)
  end

  defp submit_selected_cards_button_styling(true),
    do: "px-4 py-2 rounded bg-blue-500 hover:bg-blue-700 text-white"

  defp submit_selected_cards_button_styling(false),
    do: "px-4 py-2 rounded bg-gray-300 text-gray-500 cursor-not-allowed"
end
