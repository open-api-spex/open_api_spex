defmodule PhoenixApp.Accounts do
  alias PhoenixApp.Accounts.User
  alias PhoenixApp.Repo

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

  def update_user(id, params) do
    original = get_user!(id)

    original
    |> User.changeset(params)
    |> Repo.update!()
  end
end
