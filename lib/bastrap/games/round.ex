defmodule Bastrap.Games.Round do
  @moduledoc """
  Represents the state of a round in the game.
  """

  alias Bastrap.Games.{Player, Deck, CenterPile}

  defstruct [:dealer_index, :turn_player_index, :players, center_pile: CenterPile.new()]

  @type t :: %__MODULE__{
          dealer_index: non_neg_integer(),
          turn_player_index: non_neg_integer(),
          players: list(Player.t()),
          center_pile: CenterPile.t()
        }

  @doc """
  Creates a new round state with the given players and dealer.
  """
  @spec new(list(Player.t()), non_neg_integer()) :: t()
  def new(players, dealer_index) do
    hands = Deck.deal_hands(length(players))

    players_with_hands =
      Enum.zip(players, hands)
      |> Enum.map(fn {player, hand} -> %{player | hand: hand} end)

    turn_player_index = next_player_index(dealer_index, length(players))

    %__MODULE__{
      dealer_index: dealer_index,
      turn_player_index: turn_player_index,
      players: players_with_hands
    }
  end

  @doc """
  Creates a new round from an existing round by rotating the dealer and resetting scores.
  Preserves player order but starts fresh with zero scores.

  ## Examples
      iex> player1 = %Player{user: %{id: 1}, current_score: 5}
      iex> player2 = %Player{user: %{id: 2}, current_score: 3}
      iex> player3 = %Player{user: %{id: 3}, current_score: -6}
      iex> current_round = %Round{dealer_index: 0, players: [player1, player2, player3]}
      iex> next_round = Round.create_next_round(current_round)
      iex> {next_round.dealer_index, next_round.players |> Enum.map(&{&1.user.id, &1.current_score})}
      {1, [{1, 0}, {2, 0}, {3, 0}]}
  """
  @spec create_next_round(t()) :: t()
  def create_next_round(%__MODULE__{dealer_index: dealer_index, players: players}) do
    new_dealer_index = next_player_index(dealer_index, length(players))

    players
    |> Enum.map(&%{&1 | current_score: 0})
    |> new(new_dealer_index)
  end

  @doc """
  Advances the turn to the next player.

  ## Examples
    iex> round = %Bastrap.Games.Round{turn_player_index: 1, players: [%{}, %{}, %{}]}
    iex> Bastrap.Games.Round.pass_turn(round)
    %Bastrap.Games.Round{turn_player_index: 2, players: [%{}, %{}, %{}]}

    iex> round = %Bastrap.Games.Round{turn_player_index: 2, players: [%{}, %{}, %{}]}
    iex> Bastrap.Games.Round.pass_turn(round)
    %Bastrap.Games.Round{turn_player_index: 0, players: [%{}, %{}, %{}]}
  """
  @spec pass_turn(t()) :: t()
  def pass_turn(%__MODULE__{turn_player_index: turn_player_index, players: players} = round) do
    %{round | turn_player_index: next_player_index(turn_player_index, length(players))}
  end

  @doc """
  Calculates the index of the next player in the round.

  This function is used to determine which player should take the next turn.
  It wraps around to the first player (index 0) after the last player.

  ## Examples
    iex> Bastrap.Games.Round.next_player_index(0, 3)
    1
    iex> Bastrap.Games.Round.next_player_index(2, 3)
    0
  """
  @spec next_player_index(non_neg_integer(), pos_integer()) :: non_neg_integer()
  def next_player_index(index, num_of_players), do: rem(index + 1, num_of_players)

  @doc """
  Returns the player whose turn it currently is.

  ## Examples
    iex> players = [
    ...>   %Bastrap.Games.Player{user: %{id: 1}, display_name: "Alice"},
    ...>   %Bastrap.Games.Player{user: %{id: 2}, display_name: "Bob"},
    ...>   %Bastrap.Games.Player{user: %{id: 3}, display_name: "Charlie"}
    ...> ]
    iex> round = %Bastrap.Games.Round{turn_player_index: 1, players: players}
    iex> Bastrap.Games.Round.current_turn_player(round)
    %Bastrap.Games.Player{user: %{id: 2}, display_name: "Bob"}
  """
  @spec current_turn_player(t()) :: Player.t()
  def current_turn_player(%__MODULE__{turn_player_index: turn_player_index, players: players}) do
    players |> Enum.at(turn_player_index)
  end

  @doc """
  Checks if the round should end based on the current player's hand.

  Returns true if the current player's hand is empty,
  otherwise returns false

  ## Examples
    iex> player = %Bastrap.Games.Player{hand: %Bastrap.Games.Hand{cards: []}}
    iex> round = %Bastrap.Games.Round{players: [player], turn_player_index: 0}
    iex> Bastrap.Games.Round.should_end?(round)
    true

    iex> player = %Bastrap.Games.Player{hand: %Bastrap.Games.Hand{cards: [%Bastrap.Games.Hand.Card{}]}}
    iex> round = %Bastrap.Games.Round{players: [player], turn_player_index: 0}
    iex> Bastrap.Games.Round.should_end?(round)
    false
  """
  def should_end?(round) do
    round
    |> current_turn_player()
    |> then(fn player -> player.hand.cards end)
    |> Enum.empty?()
  end

  @doc """
  Validates if the current turn player's selected cards can beat the center pile.
  If valid, replaces the center pile with selected cards and updates player's score.

  ## Examples
      iex> player = %Bastrap.Games.Player{current_score: 0, hand: %Bastrap.Games.Hand{cards: [
      ...>   %Bastrap.Games.Hand.Card{ranks: {2, 3}, selected: true},
      ...>   %Bastrap.Games.Hand.Card{ranks: {2, 4}, selected: true}
      ...> ]}}
      iex> round = %Bastrap.Games.Round{
      ...>   center_pile: %Bastrap.Games.CenterPile{cards: [
      ...>     %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: false},
      ...>     %Bastrap.Games.Hand.Card{ranks: {1, 3}, selected: false}
      ...>   ]},
      ...>   turn_player_index: 0,
      ...>   players: [player]
      ...> }
      iex> {:ok, updated_round, score} = Bastrap.Games.Round.submit_selected_cards(round)
      iex> {updated_round.center_pile.cards |> Enum.map(& &1.ranks), score}
      {[{2, 3}, {2, 4}], 2}

      iex> player = %Bastrap.Games.Player{current_score: 0, hand: %Bastrap.Games.Hand{cards: [
      ...>   %Bastrap.Games.Hand.Card{ranks: {2, 3}, selected: true},
      ...>   %Bastrap.Games.Hand.Card{ranks: {2, 4}, selected: true}
      ...> ]}}
      iex> round = %Bastrap.Games.Round{
      ...>   center_pile: %Bastrap.Games.CenterPile{cards: [
      ...>     %Bastrap.Games.Hand.Card{ranks: {3, 4}, selected: false},
      ...>     %Bastrap.Games.Hand.Card{ranks: {3, 5}, selected: false}
      ...>   ]},
      ...>   turn_player_index: 0,
      ...>   players: [player]
      ...> }
      iex> Bastrap.Games.Round.submit_selected_cards(round)
      {:error, :card_set_not_higher}

      iex> player = %Bastrap.Games.Player{current_score: 0, hand: %Bastrap.Games.Hand{cards: [
      ...>   %Bastrap.Games.Hand.Card{ranks: {1, 2}, selected: true}
      ...> ]}}
      iex> round = %Bastrap.Games.Round{
      ...>   center_pile: %Bastrap.Games.CenterPile{cards: []},
      ...>   turn_player_index: 0,
      ...>   players: [player]
      ...> }
      iex> {:ok, updated_round, score} = Bastrap.Games.Round.submit_selected_cards(round)
      iex> {updated_round.center_pile.cards |> Enum.map(& &1.ranks), score}
      {[{1, 2}], 0}
  """
  @spec submit_selected_cards(t()) ::
          {:ok, t(), non_neg_integer()} | {:error, :card_set_not_higher}
  def submit_selected_cards(%__MODULE__{center_pile: center_pile} = round) do
    if selected_cards_beat_center?(round) do
      updated_player =
        current_turn_player(round)
        |> Player.increase_score(CenterPile.size(center_pile))
        |> Player.remove_selected_cards()

      round
      |> replace_center_pile_with_selected_cards()
      |> replace_turn_player(updated_player)
      |> then(fn updated_round ->
        {:ok, updated_round, current_turn_player(updated_round).current_score}
      end)
    else
      {:error, :card_set_not_higher}
    end
  end

  defp selected_cards_beat_center?(round) do
    center_pile_ranks = round.center_pile.cards |> Enum.map(& &1.ranks)

    selected_card_ranks =
      round
      |> current_turn_player()
      |> Player.selected_card_ranks()

    Deck.CardSet.higher_than?(selected_card_ranks, center_pile_ranks)
  end

  defp replace_turn_player(%{turn_player_index: index, players: players} = round, updated_player) do
    players
    |> List.replace_at(index, updated_player)
    |> then(fn updated_players -> %{round | players: updated_players} end)
  end

  defp replace_center_pile_with_selected_cards(round) do
    round
    |> current_turn_player()
    |> Player.selected_card_ranks()
    |> CenterPile.new()
    |> then(fn new_center_pile -> %__MODULE__{round | center_pile: new_center_pile} end)
  end
end
