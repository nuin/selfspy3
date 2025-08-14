defmodule SelfspyWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SelfspyWebWeb.Telemetry,
      SelfspyWeb.Repo,
      {DNSCluster, query: Application.get_env(:selfspy_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SelfspyWeb.PubSub},
      # Start activity monitoring components
      {SelfspyWeb.Monitor.ActivityMonitor, %{}},
      # Start to serve requests, typically the last entry
      SelfspyWebWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SelfspyWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SelfspyWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
