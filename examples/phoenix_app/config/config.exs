use Mix.Config

config :phoenix_app, PhoenixAppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PhoenixAppWeb.ErrorView, accepts: ~w(json)]

config :phoenix_app, ecto_repos: [PhoenixApp.Repo]

config :phoenix_app, PhoenixApp.Repo,
  adapter: Sqlite.Ecto2,
  database: "priv/repo/phoenix_app.db"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env}.exs"
