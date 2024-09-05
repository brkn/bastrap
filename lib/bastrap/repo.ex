defmodule Bastrap.Repo do
  use Ecto.Repo,
    otp_app: :bastrap,
    adapter: Ecto.Adapters.Postgres
end
