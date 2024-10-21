defmodule BastrapWeb.Game.CenterPileComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Bastrap.Games.CenterPile

  describe "CenterPileComponent.render/1" do
    test "renders center pile cards" do
      center_pile = CenterPile.new([{1, 2}, {3, 4}])

      html =
        render_component(&BastrapWeb.Game.CenterPileComponent.render/1, %{
          center_pile: center_pile
        })

      assert html =~ ~r{<div[^>]*id="center-pile"[^>]*>}
      assert html =~ ~r{<li[^>]*id="center-pile-card-0"[^>]*>.*1.*2.*</li>}s
      assert html =~ ~r{<li[^>]*id="center-pile-card-1"[^>]*>.*3.*4.*</li>}s
    end

    test "renders empty center pile" do
      html =
        render_component(&BastrapWeb.Game.CenterPileComponent.render/1, %{
          center_pile: CenterPile.new()
        })

      assert html =~ ~r{<div[^>]*id="center-pile"[^>]*>}
      refute html =~ ~r{<li[^>]*id="center-pile-card-}
    end

    test "renders selectable cards correctly" do
      center_pile = CenterPile.new([{1, 2}, {3, 4}, {5, 6}])

      html =
        render_component(&BastrapWeb.Game.CenterPileComponent.render/1, %{
          center_pile: center_pile
        })

      assert html =~ ~r{<li[^>]*id="center-pile-card-0"[^>]*class="[^"]*cursor-pointer[^"]*"}
      assert html =~ ~r{<li[^>]*id="center-pile-card-0"[^>]*phx-click="select_card"}
      refute html =~ ~r{<li[^>]*id="center-pile-card-1"[^>]*class="[^"]*cursor-pointer[^"]*"}
      refute html =~ ~r{<li[^>]*id="center-pile-card-1"[^>]*phx-click="select_card"}
      assert html =~ ~r{<li[^>]*id="center-pile-card-2"[^>]*class="[^"]*cursor-pointer[^"]*"}
      assert html =~ ~r{<li[^>]*id="center-pile-card-2"[^>]*phx-click="select_card"}
    end

    test "Marks the player_id for center pile cards as center_pile string" do
      center_pile = CenterPile.new([{1, 2}])

      html =
        render_component(&BastrapWeb.Game.CenterPileComponent.render/1, %{
          center_pile: center_pile
        })

      assert html =~ ~r{phx-value-player-id="center_pile"}
    end

    test "applies custom class" do
      html =
        render_component(&BastrapWeb.Game.CenterPileComponent.render/1, %{
          center_pile: CenterPile.new(),
          class: "custom-class"
        })

      assert html =~ ~r{<div[^>]*id="center-pile"[^>]*class="custom-class"[^>]*>}
    end
  end
end
