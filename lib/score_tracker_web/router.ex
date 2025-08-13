defmodule ScoreTrackerWeb.Router do
  use ScoreTrackerWeb, :router

  alias ScoreTrackerWeb.Plugs.UserIdPlug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ScoreTrackerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug UserIdPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ScoreTrackerWeb do
    pipe_through :browser

    live_session :game do
      live "/", HomeLive, :page
      live "/game/:game_id", GameLive, :page
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ScoreTrackerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:score_tracker, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ScoreTrackerWeb.Telemetry
    end
  end
end
