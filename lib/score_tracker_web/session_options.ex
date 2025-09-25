defmodule ScoreTrackerWeb.SessionOptions do
  @moduledoc """
  Functions for runtime configuration
  of sessions
  """

  @doc """
  Get the session options for the endpoint
  """
  @spec get() :: keyword()
  def get do
    [
      store: :cookie,
      http_only: true,
      key: "_score_tracker_key",
      signing_salt: {__MODULE__, :session_signing_salt, []},
      same_site: "Lax"
    ]
  end

  @doc """
  Get the session signing salt value
  """
  @spec session_signing_salt() :: String.t()
  def session_signing_salt do
    ScoreTracker.Config.get().app.session_signing_salt
  end
end
