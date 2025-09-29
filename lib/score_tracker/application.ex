defmodule ScoreTracker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScoreTrackerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:score_tracker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ScoreTracker.PubSub},
      ScoreTracker.Cache,
      {ScoreTracker.GameManager,
       name: ScoreTracker.GameManager,
       storage_backend: ScoreTracker.GameStorage.Cache,
       storage_backend_opts: []},
      ScoreTrackerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScoreTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScoreTrackerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
