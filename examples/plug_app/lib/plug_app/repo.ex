defmodule PlugApp.Repo do
  use Ecto.Repo, otp_app: :plug_app, adapter: Ecto.Adapters.SQLite3
end
