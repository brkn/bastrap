defmodule Bastrap.Games do
  alias Phoenix.PubSub

  @type user_t :: Bastrap.Accounts.User.t()
  @type game_id_t :: Ecto.UUID.t()
  @type player_card_id_t :: %{:card_index => non_neg_integer(), :player_id => non_neg_integer()}

  @spec create_game(user_t) :: {:error, any()} | {:ok, %{id: any(), pid: pid()}}
  def create_game(admin) do
    case Bastrap.Games.Supervisor.create_game(admin) do
      {:ok, pid} ->
        game_id = GenServer.call(pid, :get_id)
        {:ok, %{id: game_id, pid: pid}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec join_game(game_id_t(), user_t()) :: {:error, :not_found} | {:ok, :joining}
  def join_game(game_id, user) do
    case game_pid(game_id) do
      {:ok, pid} -> GenServer.cast(pid, {:join, user}) |> then(fn _ -> {:ok, :joining} end)
      _ -> {:error, :not_found}
    end
  end

  @spec start_game(game_id_t(), user_t()) :: {:error, :not_found} | {:ok, :starting}
  def start_game(game_id, user) do
    case game_pid(game_id) do
      {:ok, pid} -> GenServer.cast(pid, {:start_game, user}) |> then(fn _ -> {:ok, :starting} end)
      _ -> {:error, :not_found}
    end
  end

  @spec get_game(game_id_t()) :: {:error, :not_found} | {:ok, any()}
  def get_game(game_id) do
    case game_pid(game_id) do
      {:ok, pid} -> {:ok, GenServer.call(pid, :get_game)}
      _ -> {:error, :not_found}
    end
  end

  @spec select_card(game_id_t(), user_t(), player_card_id_t()) ::
          {:ok, :selecting_card} | {:error, :not_found}
  def select_card(game_id, user, player_card_id) do
    case game_pid(game_id) do
      {:ok, pid} ->
        GenServer.cast(pid, {:select_card, user, player_card_id})
        {:ok, :selecting_card}

      _ ->
        {:error, :not_found}
    end
  end

  @spec submit_selected_cards(game_id_t(), user_t()) ::
          {:ok, :submitting_cards} | {:error, :not_found}
  def submit_selected_cards(game_id, user) do
    case game_pid(game_id) do
      {:ok, pid} ->
        GenServer.cast(pid, {:submit_selected_cards, user})
        {:ok, :submitting_cards}

      _ ->
        {:error, :not_found}
    end
  end

  @spec subscribe_to_game(game_id_t()) :: :ok | {:error, {:already_registered, pid()}}
  def subscribe_to_game(game_id) do
    PubSub.subscribe(Bastrap.PubSub, "game:#{game_id}")
  end

  defp game_pid(game_id) do
    case Registry.lookup(Bastrap.Games.Registry, game_id) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  def put_game(game) do
    case game_pid(game.id) do
      {:ok, pid} -> GenServer.call(pid, {:put_game, game})
      _ -> {:error, :not_found}
    end
  end
end
