defmodule ScoreTrackerWeb.SessionOptions do
  @moduledoc """
  Functions for runtime configuration
  of sessions
  """

  @secure not Application.compile_env(:score_tracker, :dev_routes, false)

  @doc """
  Get the session options for the endpoint
  """
  @spec get() :: keyword()
  def get do
    [
      store: :cookie,
      key: "_score_tracker_key",
      http_only: true,
      secure: @secure,
      encrypt: true,
      sign: true,
      max_age: 30 * 24 * 60 * 60,
      encryption_salt: {__MODULE__, :encryption_salt, []},
      signing_salt: {__MODULE__, :signing_salt, []},
      same_site: "Strict"
    ]
  end

  @doc """
  Get the session encryption salt value
  """
  @spec encryption_salt() :: String.t()
  def encryption_salt do
    ScoreTracker.Config.get().app.session_encryption_salt
  end

  @doc """
  Get the session signing salt value
  """
  @spec signing_salt() :: String.t()
  def signing_salt do
    ScoreTracker.Config.get().app.session_signing_salt
  end
end
