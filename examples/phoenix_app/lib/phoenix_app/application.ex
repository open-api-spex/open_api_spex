defmodule PhoenixApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      PhoenixAppWeb.Endpoint,
      PhoenixApp.Repo
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PhoenixApp.Supervisor)
  end

  def config_change(changed, _new, removed) do
    PhoenixAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
