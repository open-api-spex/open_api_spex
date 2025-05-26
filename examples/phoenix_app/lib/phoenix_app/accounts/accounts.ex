defmodule PhoenixApp.Accounts do
  alias PhoenixApp.Accounts.User
  alias PhoenixApp.Repo

  import Ecto.Query

  def list_users(filters) do
    query = from(u in User, order_by: [asc: u.id])

    query =
      if filters[:ids] do
        from(u in query, where: u.id in ^filters[:ids])
      else
        query
      end

    Repo.all(query)
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
