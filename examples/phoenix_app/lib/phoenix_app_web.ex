defmodule PhoenixAppWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: PhoenixAppWeb
      alias PhoenixAppWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/phoenix_app_web/templates", namespace: PhoenixAppWeb
      alias PhoenixAppWeb.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
