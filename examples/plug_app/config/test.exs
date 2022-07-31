import Config

# Print only warnings and errors during test
config :logger, level: :warn

config :plug_app, PlugApp.Repo, pool: Ecto.Adapters.SQL.Sandbox
