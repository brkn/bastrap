defmodule BastrapWeb.Game.CardComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BastrapWeb.Game.CardComponent
  alias Bastrap.Games.Hand.Card, as: HandCard

  describe "render/1" do
    test "renders a card with correct values and classes for current player" do
      card = HandCard.new({3, 7})
      html = render_component(&CardComponent.render/1, %{card: card, id: "test-card"})

      assert html =~
               ~r{<li id="test-card"[^>]*class="[^"]*flex-shrink-0 w-10 h-14[^"]*bg-red-600[^"]*"}

      assert html =~ ~r{<p[^>]*class="[^"]*absolute top-0 left-0.5[^"]*">\s*3\s*</p>}
      assert html =~ ~r{<p[^>]*class="[^"]*absolute bottom-0 right-0.5[^"]*">\s*7\s*</p>}
    end

    test "renders a card back for opponent" do
      card = HandCard.new(:face_down)
      html = render_component(&CardComponent.render/1, %{card: card, id: "test-card"})

      assert html =~
               ~r{<li id="test-card"[^>]*class="[^"]*flex-shrink-0 w-10 h-14[^"]*bg-blue-500[^"]*"}

      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
    end

    test "applies selected class when card is selected" do
      card = HandCard.new({3, 7}, selected: true)
      html = render_component(&CardComponent.render/1, %{card: card, id: "test-card"})

      assert html =~ ~r{class="[^"]*ring-2 ring-yellow-400[^"]*"}
    end

    test "applies selectable class when card is selectable" do
      card = HandCard.new({3, 7}, selectable: true)
      html = render_component(&CardComponent.render/1, %{card: card, id: "test-card"})

      assert html =~ ~r{class="[^"]*cursor-pointer hover:ring-2 hover:ring-green-400[^"]*"}
    end

    test "applies both selected and selectable classes when card is both" do
      card = HandCard.new({3, 7}, selected: true, selectable: true)
      html = render_component(&CardComponent.render/1, %{card: card, id: "test-card"})

      assert html =~
               ~r{class="[^"]*ring-2 ring-yellow-400[^"]*cursor-pointer hover:ring-2 hover:ring-green-400[^"]*"}
    end

    test "does not show ranks for face-down cards" do
      card = HandCard.new(:face_down)
      html = render_component(&CardComponent.render/1, %{card: card, id: "test-card"})

      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
      refute html =~ ~r{<p[^>]*class="[^"]*absolute[^"]*">}
    end
  end
end
