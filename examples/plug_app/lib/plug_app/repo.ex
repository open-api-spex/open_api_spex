defmodule PlugApp.Repo do
  use Ecto.Repo, otp_app: :plug_app, adapter: Sqlite.Ecto2
end