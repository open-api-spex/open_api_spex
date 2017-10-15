defmodule PhoenixApp.Repo do
  use Ecto.Repo, otp_app: :phoenix_app, adapter: Sqlite.Ecto2
end