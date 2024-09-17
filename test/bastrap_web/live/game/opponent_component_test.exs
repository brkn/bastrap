defmodule BastrapWeb.Game.OpponentComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bastrap.AccountsFixtures
  alias Bastrap.Games.Player

  @default_sample_hand [{1, 2}, {3, 4}, {5, 6}]
  @opponent_display_name "bob"
  @opponent_id "opponent-#{@opponent_display_name}"

  @container_class_regex ~r{<li id="#{@opponent_id}"[^>]*class="[^"]+"}
  @display_name_component_regex ~r{<h3 id="opponent-display-name-#{@opponent_display_name}"[^>]*>\s*#{@opponent_display_name}\s*</h3>}
  @hand_container_regex ~r{<ol id="opponent-hand-#{@opponent_display_name}"[^>]*>}
  @card_placeholder_regex ~r{<li id="opponent-hand-#{@opponent_display_name}-card-\d+"[^>]*>}
  @card_with_a_number_regex ~r{<li id="opponent-hand-opponent-card[^>]*>[^<]*\d+}

  describe "OpponentComponent" do
    setup context do
      email = context[:email] || "#{@opponent_display_name}@example.com"
      user = AccountsFixtures.user_fixture(%{email: email})
      player = Player.new(user)
      hand = context[:hand] || @default_sample_hand

      player = %{player | hand: hand}

      html =
        render_component(&BastrapWeb.Game.OpponentComponent.render/1, %{
          id: @opponent_id,
          player: player
        })

      %{html: html, player: player}
    end

    test "renders opponent's display name", %{html: html} do
      assert html =~ @display_name_component_regex
    end

    test "renders opponent hand container", %{html: html} do
      assert html =~ @hand_container_regex
    end

    test "renders correct number of card placeholders", %{html: html} do
      card_placeholder_count = Regex.scan(@card_placeholder_regex, html) |> Enum.count()
      assert card_placeholder_count == 3
    end

    @tag hand: []
    test "renders no card placeholders for empty hand", %{html: html} do
      assert html =~ ~r{<ol id="opponent-hand-#{@opponent_display_name}"[^>]*>\s*</ol>}s
      refute html =~ @card_placeholder_regex
    end

    @tag hand: [{7, 8}]
    test "renders correct number of placeholders for hand with single card", %{html: html} do
      card_placeholder_count = Regex.scan(@card_placeholder_regex, html) |> Enum.count()
      assert card_placeholder_count == 1
    end

    test "applies non-empty class to the container", %{html: html} do
      container_item_with_non_empty_class = @container_class_regex
      assert html =~ container_item_with_non_empty_class
    end

    test "does not render card values inside hand placeholders", %{html: html} do
      refute html =~ @card_with_a_number_regex
    end
  end
end
