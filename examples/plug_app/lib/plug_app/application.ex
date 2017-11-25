defmodule PlugApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      PlugApp.Repo,
      Plug.Adapters.Cowboy.child_spec(:http, PlugApp.Router, [], [port: 4000])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PlugApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
