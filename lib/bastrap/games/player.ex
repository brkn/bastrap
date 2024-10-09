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

  # @doc """
  # Updates the player's score.
  # TODO: add test coverage
  # """
  # @spec update_score(t(), non_neg_integer()) :: t()
  # def update_score(%__MODULE__{} = player, score) do
  #   %{player | current_score: score}
  # end

  defp display_name(user) do
    user.email |> String.split("@") |> List.first()
  end
end
