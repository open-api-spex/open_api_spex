import Config

config :plug_app, ecto_repos: [PlugApp.Repo]

config :plug_app, PlugApp.Repo,
  adapter: Sqlite.Ecto2,
  database: "priv/repo/plug_app_#{Mix.env()}.db"

config :logger, level: :debug

if File.exists?(Path.join("config", "#{config_env()}.exs")) do
  import_config "#{config_env()}.exs"
end
