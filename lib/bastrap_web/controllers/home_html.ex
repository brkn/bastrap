defmodule BastrapWeb.HomeHTML do
  use BastrapWeb, :html

  def index(assigns) do
    ~H"""
      <div class="container mx-auto">
        <h1 class="text-4xl font-bold mb-4">Welcome to Bastrap</h1>
        <%= if @current_user do %>
          <.link href={~p"/game"} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            Join Game
          </.link>
        <% else %>
          <.link
            href={~p"/users/register"}
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Register
          </.link>
          <.link
            href={~p"/users/log_in"}
            class="ml-4 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Login
          </.link>
        <% end %>
      </div>
    """
  end
end
