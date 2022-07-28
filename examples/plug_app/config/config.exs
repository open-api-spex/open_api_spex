# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :plug_app, ecto_repos: [PlugApp.Repo]

config :plug_app, PlugApp.Repo,
  adapter: Sqlite.Ecto2,
  database: "priv/repo/plug_app_#{Mix.env()}.db"

config :logger, level: :debug

if File.exists?(Path.join("config", "#{Mix.env()}.exs")) do
  import_config "#{Mix.env()}.exs"
end
