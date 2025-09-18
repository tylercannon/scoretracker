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
          },
          cache: %{
            pool_size: non_neg_integer(),
            url: String.t()
          }
        }

  @doc """
  Get application configuration values
  """
  @spec get() :: t()
  def get do
    app = Application.get_env(@app, :app)
    cache = Application.get_env(@app, :cache)

    %{
      app: %{
        session_signing_salt: Keyword.fetch!(app, :session_signing_salt),
        version: @version
      },
      cache: %{
        pool_size: Keyword.fetch!(cache, :pool_size),
        url: Keyword.fetch!(cache, :url)
      }
    }
  end
end
