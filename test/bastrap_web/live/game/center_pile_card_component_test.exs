defmodule BastrapWeb.Game.CenterPileCardComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.Games.Hand.Card, as: HandCard
  alias BastrapWeb.Game.CenterPileCardComponent

  describe "CenterPileCardComponent" do
    test "renders a card with correct values and classes" do
      card = HandCard.new({3, 7}, selectable: true)

      html =
        render_component(&CenterPileCardComponent.render/1, %{
          id: "test-card",
          card: card,
          index: 0
        })

      assert html =~
               ~r{<li id="test-card"[^>]*class="[^"]*flex-shrink-0 w-10 h-14[^"]*bg-red-600[^"]*"}

      assert html =~ ~r{<p[^>]*class="[^"]*absolute top-0 left-0.5[^"]*">\s*3\s*</p>}
      assert html =~ ~r{<p[^>]*class="[^"]*absolute bottom-0 right-0.5[^"]*">\s*7\s*</p>}
    end

    test "renders a face-down card" do
      card = HandCard.new(:face_down, selectable: true)

      html =
        render_component(&CenterPileCardComponent.render/1, %{
          id: "test-card",
          card: card,
          index: 0
        })

      assert html =~
               ~r{<li id="test-card"[^>]*class="[^"]*flex-shrink-0 w-10 h-14[^"]*bg-blue-500[^"]*"}

      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
    end

    test "applies selected class when card is selected" do
      card = HandCard.new({3, 7}, selected: true, selectable: true)

      html =
        render_component(&CenterPileCardComponent.render/1, %{
          id: "test-card",
          card: card,
          index: 0
        })

      assert html =~ ~r{class="[^"]*ring-2 ring-yellow-400[^"]*"}
    end

    test "applies selectable class when card is selectable" do
      card = HandCard.new({3, 7}, selectable: true)

      html =
        render_component(&CenterPileCardComponent.render/1, %{
          id: "test-card",
          card: card,
          index: 0
        })

      assert html =~ ~r{class="[^"]*cursor-pointer hover:ring-2 hover:ring-green-400[^"]*"}
    end
  end
end
