import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :score_tracker, ScoreTrackerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

# Use ETS storage backend for tests
config :score_tracker, :game_storage_backend, ScoreTracker.GameStorage.Ets

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
