defmodule Bastrap.Games.ErrorHandler do
  @moduledoc """
  Handles error message humanization for game-related errors.
  """

  @doc """
  Converts internal error atoms into human-readable messages.

  ## Examples
    iex> Bastrap.Games.ErrorHandler.humanize(:not_enough_players)
    "Need at least 3 players to start the game"

    iex> Bastrap.Games.ErrorHandler.humanize(:too_many_players)
    "Can't have more than 5 players"

    iex> Bastrap.Games.ErrorHandler.humanize("Custom error message")
    "Custom error message"

    iex> Bastrap.Games.ErrorHandler.humanize(:unknown_error)
    "An error occurred"
  """
  @spec humanize(atom() | String.t()) :: String.t()
  def humanize(:not_enough_players), do: "Need at least 3 players to start the game"
  def humanize(:too_many_players), do: "Can't have more than 5 players"
  def humanize(:not_your_turn), do: "Not your turn"
  def humanize(:card_set_not_higher), do: "Selected cards must be higher than center pile"
  def humanize(:card_not_selectable), do: "Card is not selectable"
  def humanize(:invalid_index), do: "Invalid card index"
  def humanize(error) when is_binary(error), do: error
  # TODO: we should log an error when we have untranslated error sym
  def humanize(_), do: "An error occurred"
end
