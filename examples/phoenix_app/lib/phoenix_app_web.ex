defmodule PhoenixAppWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: PhoenixAppWeb
      import PhoenixAppWeb.Router.Helpers
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/phoenix_app_web/templates", namespace: PhoenixAppWeb
      import PhoenixAppWeb.Router.Helpers
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
