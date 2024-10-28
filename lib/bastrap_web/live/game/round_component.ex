defmodule BastrapWeb.Game.RoundComponent do
  use BastrapWeb, :live_component

  alias BastrapWeb.Game.{OpponentComponent, CurrentPlayerComponent, CenterPileComponent}
  alias Bastrap.Games
  alias Bastrap.Games.Round
  alias Bastrap.Games.Player

  def render(assigns) do
    %{
      round: round,
      current_user: current_user
    } = assigns

    {current_player, opponents} = partition_players(round.players, current_user)

    assigns =
      assign(
        assigns,
        current_player: current_player,
        opponents: opponents,
        current_turn_player: Round.current_turn_player(round)
      )

    ~H"""
    <section id="round-container" class="container h-full min-w-min mx-auto">
      <h2 id="current-turn" class="bg-green-100 rounded-lg p-4 mb-4 text-xl font-bold text-center">
        Current Turn: <%= @current_turn_player.display_name %>
      </h2>

      <div
        id="game-grid"
        class="grid grid-cols-[420px_auto_420px] grid-rows-2 place-items-center gap-2 mb-2 h-4/5"
        style="grid-template-areas:
        'opp1 game opp2'
        'opp3 game opp4';"
      >
        <%= for player <- @opponents do %>
          <OpponentComponent.render id={"opponent-#{player.display_name}"} player={player} />
        <% end %>

        <.live_component
          module={CenterPileComponent}
          id="center-pile"
          center_pile={@round.center_pile}
        />
      </div>

      <CurrentPlayerComponent.render id="current-player" player={@current_player} />
    </section>
    """
  end

  def handle_event("submit_selected_cards", _, socket) do
    %{game_id: game_id, current_user: current_user} = socket.assigns

    case Games.submit_selected_cards(game_id, current_user) do
      {:ok, :submitting_cards} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to submit cards: #{reason}")}
    end
  end

  # TODO: handle this
  def handle_event("select_card", %{"index" => index, "player-id" => "center_pile"}, socket) do
    IO.inspect("Clicked on center pile card #{index}")
    {:noreply, socket}
  end

  def handle_event("select_card", %{"index" => card_index, "player-id" => player_id}, socket) do
    %{game_id: game_id, current_user: current_user} = socket.assigns

    player_card_id = %{
      card_index: String.to_integer(card_index),
      player_id: String.to_integer(player_id)
    }

    case Games.select_card(game_id, current_user, player_card_id) do
      {:ok, :selecting_card} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to select card: #{reason}")}
    end
  end

  defp partition_players(players, current_user) do
    {[current_player], other_players} =
      players |> Enum.split_with(&(&1.user.id == current_user.id))

    opponents =
      other_players
      |> Enum.map(&Player.to_opponent_player(&1))

    {current_player, opponents}
  end
end
