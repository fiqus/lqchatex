import Config

config :live_qchatex, LiveQchatexWeb.Endpoint,
  debug_errors: false

# Configures Memento/Mnesia
config :mnesia,
  # Notice the single quotes
  dir: '.mnesia/rel/#{System.fetch_env!("RELEASE_NODE")}'
