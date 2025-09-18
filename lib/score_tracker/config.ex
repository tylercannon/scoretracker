defmodule ScoreTracker.Config do
  @moduledoc """
  Application configuration values
  """

  @app Mix.Project.config()[:app]
  @version Mix.Project.config()[:version]

  @type t :: %{
          app: %{
            session_signing_salt: String.t(),
            version: String.t()
          }
        }

  @doc """
  Get application configuration values
  """
  @spec get() :: t()
  def get do
    app = Application.get_env(@app, :app)

    %{
      app: %{
        session_signing_salt: Keyword.fetch!(app, :session_signing_salt),
        version: @version
      }
    }
  end
end
