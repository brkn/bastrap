defmodule Bastrap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BastrapWeb.Telemetry,
      Bastrap.Repo,
      {DNSCluster, query: Application.get_env(:bastrap, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bastrap.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Bastrap.Finch},
      # Start a worker by calling: Bastrap.Worker.start_link(arg)
      # {Bastrap.Worker, arg},
      # Start to serve requests, typically the last entry
      BastrapWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bastrap.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BastrapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
