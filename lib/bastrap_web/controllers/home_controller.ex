defmodule BastrapWeb.HomeController do
  use BastrapWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
