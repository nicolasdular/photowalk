defmodule P.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ensure_upload_root!()

    :logger.add_handler(:my_sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

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

  defp ensure_upload_root! do
    prefix = Application.get_env(:waffle, :storage_dir_prefix, "priv/waffle/public")
    storage_dir = Application.get_env(:waffle, :storage_dir, "uploads")

    prefix
    |> Path.join(storage_dir)
    |> resolve_upload_path()
    |> File.mkdir_p!()
  end

  defp resolve_upload_path(path) do
    case Path.type(path) do
      :absolute -> path
      _ -> :photowalk |> Application.app_dir(path) |> to_string()
    end
  end
end
