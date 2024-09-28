defmodule Bastrap.Games.Supervisor do
  @moduledoc """
  Supervisor for managing game servers.
  """

  use DynamicSupervisor

  @doc """
  Starts the supervisor.
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a new game server for the given admin user.
  """
  @spec create_game(Bastrap.Accounts.User.t()) :: DynamicSupervisor.on_start_child()
  def create_game(admin) do
    DynamicSupervisor.start_child(__MODULE__, {Bastrap.Games.Server, admin})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
