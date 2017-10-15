use Mix.Config

config :phoenix_app, PhoenixAppWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
