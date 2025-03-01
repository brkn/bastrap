defmodule Bastrap.Games.Player do
  @moduledoc """
  Represents a player in the game.
  """
  alias Bastrap.Games.Hand

  defstruct [:user, :display_name, :hand, current_score: 0]

  @type t :: %__MODULE__{
          user: Bastrap.Accounts.User.t(),
          display_name: String.t(),
          hand: Hand.t(),
          current_score: non_neg_integer()
        }

  @doc """
  Creates a new player with the given user and an empty hand.
  """
  @spec new(Bastrap.Accounts.User.t()) :: t()
  def new(user) do
    %__MODULE__{
      user: user,
      display_name: display_name(user),
      hand: Hand.new(),
      current_score: 0
    }
  end

  @doc """
  Updates the player's score by adding the given points.

  ## Examples
    iex> player = %Bastrap.Games.Player{current_score: 10}
    iex> Bastrap.Games.Player.increase_score(player, 5)
    %Bastrap.Games.Player{current_score: 15}

    iex> player = %Bastrap.Games.Player{current_score: 10}
    iex> Bastrap.Games.Player.increase_score(player, 0)
    %Bastrap.Games.Player{current_score: 10}
  """
  @spec increase_score(t(), non_neg_integer()) :: t()
  def increase_score(%__MODULE__{current_score: current_score} = player, points) do
    %{player | current_score: current_score + points}
  end

  @doc """
  Removes the selected cards from the player's hand.

  ## Examples
    iex> hand = %Bastrap.Games.Hand{cards: [
    ...>   %Bastrap.Games.Hand.Card{ranks: {9, 2}, selected: false},
    ...>   %Bastrap.Games.Hand.Card{ranks: {8, 4}, selected: false},
    ...>   %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: true},
    ...>   %Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: true},
    ...>   %Bastrap.Games.Hand.Card{ranks: {5, 6}, selected: false}
    ...> ]}
    iex> player = %Bastrap.Games.Player{hand: hand, user: %{id: 123}}
    iex> Bastrap.Games.Player.remove_selected_cards(player)
    %Bastrap.Games.Player{
      user: %{id: 123},
      display_name: nil,
      current_score: 0,
      hand: %Bastrap.Games.Hand{cards: [
        %Bastrap.Games.Hand.Card{ranks: {9, 2}, selected: false, selectable: false},
        %Bastrap.Games.Hand.Card{ranks: {8, 4}, selected: false, selectable: false},
        %Bastrap.Games.Hand.Card{ranks: {5, 6}, selected: false, selectable: false}
        ]}
      }
  """
  @spec remove_selected_cards(t()) :: t()
  def remove_selected_cards(player) do
    %{player | hand: Hand.remove_selected_cards(player.hand)}
  end

  def selected_card_ranks(player), do: Hand.selected_card_set(player.hand)

  @doc """
  Calculates the final score for a round by subtracting penalties for remaining cards.
  IMPORTANT: make sure to pass a round player struct, not a game player struct.

  ## Examples
      iex> hand = %Bastrap.Games.Hand{cards: [{1, 2}, {3, 4}]}
      iex> player = %Bastrap.Games.Player{current_score: 5, hand: hand}
      iex> Bastrap.Games.Player.net_round_score(player)
      3  # 5 points earned - 2 cards penalty
  """
  @spec net_round_score(t()) :: integer()
  def net_round_score(%__MODULE__{current_score: score, hand: hand}) do
    score - length(hand.cards)
  end

  @doc """
  Converts a player's view to an opponent's view by hiding their card ranks.
  Keeps the player's metadata but makes their hand face-down and unselectable.

  ## Examples
      iex> hand = %Bastrap.Games.Hand{cards: [
      ...>   %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: false, selectable: true}
      ...> ]}
      iex> player = %Bastrap.Games.Player{
      ...>   user: %{id: 1, email: "test@example.com"},
      ...>   display_name: "test",
      ...>   hand: hand,
      ...>   current_score: 10
      ...> }
      iex> Bastrap.Games.Player.to_opponent_player(player)
      %Bastrap.Games.Player{
        user: %{id: 1, email: "test@example.com"},
        current_score: 10,
        display_name: "test",
        hand: %Bastrap.Games.Hand{cards: [
          %Bastrap.Games.Hand.Card{ranks: :face_down, selected: false, selectable: false}
        ]}
      }
  """
  @spec to_opponent_player(t()) :: t()
  def to_opponent_player(player) do
    player.hand
    |> Hand.to_opponent_hand()
    |> then(&%{player | hand: &1})
  end

  defp display_name(user) do
    user.email |> String.split("@") |> List.first()
  end
end
