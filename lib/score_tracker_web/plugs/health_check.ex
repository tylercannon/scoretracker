defmodule ScoreTrackerWeb.Plugs.HealthCheck do
  @moduledoc """
  Public health check endpoint.
  This is done as a plug so we don't get logging for it
  """

  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{request_path: "/v1/health", method: "GET"} = conn, _opts) do
    conn
    |> send_resp(200, "OK")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
