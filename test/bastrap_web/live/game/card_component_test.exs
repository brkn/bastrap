defmodule BastrapWeb.Game.CardComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BastrapWeb.Game.CardComponent
  alias Bastrap.Games.Hand.Card, as: HandCard

  @default_parameters %{
    id: "test-card",
    index: 2,
    player_id: "player-sdfu132"
  }

  describe "render/1" do
    setup context do
      card = context[:card]
      card_parameters = @default_parameters |> Map.put(:card, card)

      html = render_component(&CardComponent.render/1, card_parameters)

      %{html: html}
    end

    @tag card: HandCard.new({3, 7})
    test "renders a card with correct values and classes for current player", %{html: html} do
      assert html =~
               ~r{<li id="test-card"[^>]*class="[^"]*flex-shrink-0 w-10 h-14[^"]*bg-red-600[^"]*"}

      assert html =~ ~r{<p[^>]*class="[^"]*absolute top-0 left-0.5[^"]*">\s*3\s*</p>}
      assert html =~ ~r{<p[^>]*class="[^"]*absolute bottom-0 right-0.5[^"]*">\s*7\s*</p>}
    end

    @tag card: HandCard.new(:face_down)
    test "renders a card back for opponent", %{html: html} do
      assert html =~
               ~r{<li id="test-card"[^>]*class="[^"]*flex-shrink-0 w-10 h-14[^"]*bg-blue-500[^"]*"}

      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
    end

    @tag card: HandCard.new({3, 7}, selected: true)
    test "applies selected class when card is selected", %{html: html} do
      assert html =~ ~r{class="[^"]*ring-2 ring-yellow-400[^"]*"}
    end

    @tag card: HandCard.new({3, 7}, selectable: true)
    test "applies selectable class when card is selectable", %{html: html} do
      assert html =~ ~r{class="[^"]*cursor-pointer hover:ring-2 hover:ring-green-400[^"]*"}
    end

    @tag card: HandCard.new({3, 7}, selected: true, selectable: true)
    test "applies both selected and selectable classes when card is both", %{html: html} do
      assert html =~
               ~r{class="[^"]*ring-2 ring-yellow-400[^"]*cursor-pointer hover:ring-2 hover:ring-green-400[^"]*"}
    end

    @tag card: HandCard.new(:face_down)
    test "does not show ranks for face-down cards", %{html: html} do
      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
    end

    @tag card: HandCard.new({3, 7}, selectable: true)
    test "includes phx-click attribute when card is selectable", %{html: html} do
      assert html =~ ~r{phx-click="select_card"}
      assert html =~ ~r{phx-target="#round-container"}
      assert html =~ ~r{phx-value-index="2"}
      assert html =~ ~r{phx-value-player-id="player-sdfu132"}
    end

    @tag card: HandCard.new({3, 7}, selectable: false)
    test "does not include phx-click attribute when card is not selectable", %{html: html} do
      refute html =~ ~r{phx-click="select_card"}
      refute html =~ ~r{phx-value-index="2"}
      refute html =~ ~r{phx-value-player-id="player-sdfu132"}
      refute html =~ ~r{phx-target="#round-container"}
    end
  end
end
