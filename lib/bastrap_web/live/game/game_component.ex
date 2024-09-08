defmodule BastrapWeb.Game.GameComponent do
  use BastrapWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-4 text-center">Game in Progress</h1>
      </div>
    """
  end
end
