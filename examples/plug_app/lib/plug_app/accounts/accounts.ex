defmodule PlugApp.Accounts do
  alias PlugApp.Accounts.User
  alias PlugApp.Repo

  def list_users() do
    Repo.all(User)
  end

  def get_user!(id) do
    Repo.get(User, id)
  end

  def create_user(%{name: name, email: email}) do
    user = Repo.insert!(%User{name: name, email: email})
    {:ok, user}
  end
end
