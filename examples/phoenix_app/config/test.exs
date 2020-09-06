use Mix.Config

config :phoenix_app, PhoenixAppWeb.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :warn

config :phoenix_app, PhoenixApp.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :phoenix_app, PhoenixApp.Repo,
  adapter: Sqlite.Ecto2,
  database: "priv/repo/phoenix_app_test.db"
