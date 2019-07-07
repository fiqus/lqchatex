# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :live_qchatex, LiveQchatexWeb.Endpoint,
  environment: Mix.env(),
  url: [host: "localhost"],
  secret_key_base: "29YRW8+WiK13N3OJb0xPWIcOXSDHQ+BKW3Ext0j1f0g8QAcMF1hc1L9oICeJXCC6",
  render_errors: [view: LiveQchatexWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: LiveQchatex.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "5VEQz06OfXTZJdJquA2C3zKPgmZE37jI7ev5HjLeDdeF9fjGHENmRilIbG5Rf3gz"]

# Configures app timers in SECONDS
config :live_qchatex, :timers,
  cron_interval_clean_chats: 60 * 30,
  cron_interval_clean_users: 60 * 10,
  user_typing_timeout: 3

# Configures Memento/Mnesia
config :mnesia,
  # Notice the single quotes
  dir: '.mnesia/#{Mix.env()}/#{node()}'

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine

# config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
