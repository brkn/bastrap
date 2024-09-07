defmodule Bastrap.Games.Supervisor do
  use DynamicSupervisor

  # It's used to start the GameSupervisor itself, typically when your application starts up. This function is called by
  # your application's supervision tree to start the GameSupervisor as part of your overall application structure.
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # is a convenience function that uses the running supervisor to start a new GameServer child process.
  def start_game(admin) do
    DynamicSupervisor.start_child(__MODULE__, {Bastrap.Games.Server, admin})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
