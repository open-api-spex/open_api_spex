defmodule PhoenixAppWeb.UserController do
  use PhoenixAppWeb, :controller
  alias PhoenixApp.{Accounts, Accounts.User}
  alias PhoenixAppWeb.Schemas

  defdelegate open_api_operation(action), to: PhoenixAppWeb.UserApiOperation
  
  plug OpenApiSpex.Plug.CastAndValidate

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn = %{body_params: %Schemas.UserRequest{user: user_params}}, %{
        group_id: _group_id
      }) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  def show(conn, %{id: id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end
end
