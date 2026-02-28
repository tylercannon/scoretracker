defmodule ScoreTrackerWeb.Plugs.UserIdPlug do
  @moduledoc """
  Put an anonymous user id into the session
  if it doesn't already exist.
  """

  alias Ecto.UUID

  import Plug.Conn, only: [get_session: 2, put_session: 3]

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      put_session(conn, :user_id, UUID.generate())
    else
      conn
    end
  end
end
