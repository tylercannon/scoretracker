import Config
import Dotenvy

source([".env", System.get_env()])

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/score_tracker start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :score_tracker, ScoreTrackerWeb.Endpoint, server: true
end

config :score_tracker, ScoreTrackerWeb.Endpoint,
  secret_key_base: env!("SCORE_TRACKER_SECRET_KEY_BASE", :string!),
  live_view: [signing_salt: env!("SCORE_TRACKER_LIVE_VIEW_SIGNING_SALT", :string!)]

config :score_tracker,
  app: [
    session_encryption_salt: env!("SCORE_TRACKER_SESSION_ENCRYPTION_SALT", :string!),
    session_signing_salt: env!("SCORE_TRACKER_SESSION_SIGNING_SALT", :string!)
  ],
  cache: [
    pool_size: env!("SCORE_TRACKER_CACHE_POOL_SIZE", :integer!),
    url: env!("SCORE_TRACKER_CACHE_URL", :string!)
  ]

if config_env() == :prod do
  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :score_tracker, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :score_tracker, ScoreTrackerWeb.Endpoint,
    url: [host: host, port: port],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :score_tracker, ScoreTrackerWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :score_tracker, ScoreTrackerWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
