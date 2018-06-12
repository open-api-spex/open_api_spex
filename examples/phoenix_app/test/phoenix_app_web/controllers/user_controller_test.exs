defmodule PhoenixAppWeb.UserControllerTest do
  use PhoenixAppWeb.ConnCase, async: true
  import OpenApiSpex.Test.Assertions

  setup do
    %{spec: PhoenixAppWeb.ApiSpec.spec()}
  end

  test "create user", %{conn: conn, spec: spec} do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> post(user_path(conn, :create), %{"user" => %{"name" => "Joe", "email" => "joe@gmail.com"}, "group_id" => 1})
    |> json_response(201)
    |> assert_schema("UserResponse", spec)
  end

  test "get user", %{conn: conn, spec: spec} do
    %{id: id} = PhoenixApp.Repo.insert!(%PhoenixApp.Accounts.User{name: "Carl", email: "Carl@yahoo.com"})

    conn
    |> Plug.Conn.put_req_header("accept", "application/json")
    |> get(user_path(conn, :show, id))
    |> json_response(200)
    |> assert_schema("UserResponse", spec)
  end

  test "list users", %{conn: conn, spec: spec} do
    %{id: id1} = PhoenixApp.Repo.insert!(%PhoenixApp.Accounts.User{name: "Aaron", email: "aaron@hotmail.com"})
    %{id: id2} = PhoenixApp.Repo.insert!(%PhoenixApp.Accounts.User{name: "Benjamin", email: "ben@lycos.com"})
    %{id: id3} = PhoenixApp.Repo.insert!(%PhoenixApp.Accounts.User{name: "Chuck", email: "chuck@aol.com"})

    response =
      conn
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> get(user_path(conn, :index))
      |> json_response(200)
      |> assert_schema("UsersResponse", spec)

    assert [%{id: ^id1}, %{id: ^id2}, %{id: ^id3}] = response.data
  end

  test "User schema example", %{spec: spec} do
    assert_schema(PhoenixAppWeb.Schemas.User.schema().example, "User", spec)
  end

  test "UserRequest schema example", %{spec: spec} do
    assert_schema(PhoenixAppWeb.Schemas.UserRequest.schema().example, "UserRequest", spec)
  end

  test "UserResponse schema example", %{spec: spec} do
    assert_schema(PhoenixAppWeb.Schemas.UserResponse.schema().example, "UserResponse", spec)
  end

  test "UsersResponse schema example", %{spec: spec} do
    assert_schema(PhoenixAppWeb.Schemas.UsersResponse.schema().example, "UsersResponse", spec)
  end
end