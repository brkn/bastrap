defmodule BastrapWeb.Game.CurrentPlayerComponentTest do
  use BastrapWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bastrap.AccountsFixtures
  alias Bastrap.Games.Player

  @default_sample_hand [{1, 2}, {3, 4}, {5, 6}]

  describe "CurrentPlayerComponent" do
    setup context do
      email = context[:email] || "display_name@example.com"
      user = AccountsFixtures.user_fixture(%{email: email})
      player = Player.new(user)
      hand = context[:hand] || @default_sample_hand

      player = %{player | hand: hand}

      html =
        render_component(&BastrapWeb.Game.CurrentPlayerComponent.render/1, %{
          player: player
        })

      %{html: html, player: player}
    end

    test "renders player's display name derived from email", %{html: html} do
      assert html =~ ~r{<p id="current-player-display-name"[^>]*>\s*display_name\s*</p>}s
    end

    test "renders player hand container", %{html: html} do
      assert html =~ ~r{ol id="player-hand"[^>]*>}
    end

    test "renders correct number of cards", %{html: html} do
      assert html =~ ~r{<li id="player-card-0"[^>]*>}
      assert html =~ ~r{<li id="player-card-1"[^>]*>}
      assert html =~ ~r{<li id="player-card-2"[^>]*>}
    end

    test "renders card values correctly", %{html: html, player: %{hand: hand}} do
      Enum.with_index(hand)
      |> Enum.each(fn {card, id_index} ->
        assert_card_values(html, id_index, card)
      end)
    end

    @tag hand: []
    test "renders no card elements for empty hand", %{html: html} do
      assert html =~ ~r{ol id="player-hand"[^>]*>\s*</ol>}s
      refute html =~ ~r{<li id="player-card-}
    end

    @tag hand: [{7, 8}]
    test "renders correct number and values for hand with single card", %{html: html} do
      assert Enum.count(Regex.scan(~r{<li id="player-card-\d+"}, html)) == 1

      assert_card_values(html, 0, {7, 8})
    end
  end

  defp assert_card_values(html, id_index, {left, right}) do
    assert html =~
             ~r{<li id="player-card-#{id_index}"[^>]*>.*?<p[^>]*>\s*#{left}\s*</p>.*?<p[^>]*>\s*#{right}\s*</p>}s
  end
end
