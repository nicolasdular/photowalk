defmodule P.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PWeb.Telemetry,
      P.Repo,
      {DNSCluster, query: Application.get_env(:photowalk, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: P.PubSub},
      # Start a worker by calling: P.Worker.start_link(arg)
      # {P.Worker, arg},
      # Start to serve requests, typically the last entry
      PWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: P.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
