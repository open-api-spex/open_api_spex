defmodule PlugApp.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Plug.Test
      import Plug.Conn
      import OpenApiSpex.TestAssertions

      import OpenApiSpex.Schema, only: [example: 1]
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PlugApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PlugApp.Repo, {:shared, self()})
    end

    # Added to the context to validate responses with assert_schema/3
    api_spec = PlugApp.ApiSpec.spec()

    {:ok, api_spec: api_spec}
  end
end
