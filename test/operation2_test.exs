defmodule OpenApiSpex.Operation2Test do
  use ExUnit.Case
  alias OpenApiSpex.{Operation, Operation2, Schema, Components, Reference, RequestBody, MediaType}
  alias OpenApiSpex.Cast.Error

  defmodule SchemaFixtures do
    @user %Schema{
      type: :object,
      properties: %{
        user: %Schema{
          type: :object,
          properties: %{
            email: %Schema{type: :string}
          }
        }
      }
    }
    @user_list %Schema{
      type: :array,
      items: @user
    }
    @schemas %{"User" => @user, "UserList" => @user_list}

    def user, do: @user
    def user_list, do: @user_list
    def schemas, do: @schemas
  end

  defmodule ParameterFixtures do
    alias OpenApiSpex.{Schema, Operation}

    def parameters do
      %{
        "member" => Operation.parameter(:member, :query, :boolean, "Membership flag")
      }
    end
  end

  defmodule OperationFixtures do
    @user_index %Operation{
      operationId: "UserController.index",
      parameters: [
        Operation.parameter(:name, :query, :string, "Filter by user name"),
        Operation.parameter(:age, :query, :integer, "Filter by user age"),
        %Reference{"$ref": "#/components/parameters/member"},
        Operation.parameter(
          :include_archived,
          :query,
          %Schema{type: :boolean, default: false},
          "Example of a default value"
        )
      ],
      responses: %{
        200 => Operation.response("User", "application/json", SchemaFixtures.user())
      }
    }

    def user_index, do: @user_index

    @create_user %Operation{
      operationId: "UserController.create",
      parameters: [
        Operation.parameter(:name, :query, :string, "Filter by user name")
      ],
      requestBody:
        Operation.request_body("request body", "application/json", SchemaFixtures.user(),
          required: true
        ),
      responses: %{
        200 => Operation.response("User list", "application/json", SchemaFixtures.user_list())
      }
    }

    def create_user, do: @create_user

    @create_users %Operation{
      operationId: "UserController.create",
      parameters: [
        Operation.parameter(:name, :query, :string, "Filter by user name")
      ],
      requestBody:
        Operation.request_body("request body", "application/json", SchemaFixtures.user_list(),
          required: true
        ),
      responses: %{
        200 => Operation.response("User list", "application/json", SchemaFixtures.user_list())
      }
    }

    def create_users, do: @create_users

    @update_user %Operation{
      operationId: "UserController.update",
      parameters: [
        Operation.parameter(:name, :query, :string, "Filter by user name")
      ],
      requestBody: %Reference{"$ref": "#/components/requestBodies/updateUser"},
      responses: %{
        200 => Operation.response("User list", "application/json", SchemaFixtures.user_list())
      }
    }

    def update_user, do: @update_user
  end

  defmodule SpecModule do
    @behaviour OpenApiSpex.OpenApi

    @impl OpenApiSpex.OpenApi
    def spec do
      paths = %{
        "/users" => %{
          "post" => OperationFixtures.create_user(),
          "put" => OperationFixtures.update_user()
        }
      }

      %OpenApiSpex.OpenApi{
        info: nil,
        paths: paths,
        components: %Components{
          schemas: SchemaFixtures.schemas(),
          parameters: ParameterFixtures.parameters(),
          requestBodies: %{
            "updateUser" => %RequestBody{
              description: "update user request body",
              content: %{
                "application/json" => %MediaType{
                  schema: SchemaFixtures.user()
                }
              },
              required: true
            }
          }
        }
      }
    end
  end

  defmodule RenderError do
    def init(_) do
      nil
    end

    def call(_conn, _errors) do
      raise "should not have errors"
    end
  end

  describe "cast/4" do
    test "cast request body" do
      conn = create_conn(%{"user" => %{"email" => "foo@bar.com"}})

      assert {:ok, conn} =
               Operation2.cast(
                 OperationFixtures.create_user(),
                 conn,
                 "application/json",
                 SpecModule.spec().components
               )

      assert %Plug.Conn{} = conn
    end

    test "cast request body reference" do
      conn = put_conn(%{"user" => %{"email" => "foo@bar.com"}})

      assert {:ok, conn} =
               Operation2.cast(
                 OperationFixtures.update_user(),
                 conn,
                 "application/json",
                 SpecModule.spec().components
               )

      assert %Plug.Conn{} = conn
    end

    test "cast array request body" do
      conn = create_conn([%{"user" => %{"email" => "foo@bar.com"}}])

      assert {:ok, conn} =
               Operation2.cast(
                 OperationFixtures.create_users(),
                 conn,
                 "application/json",
                 SpecModule.spec().components
               )

      assert %Plug.Conn{} = conn
    end

    test "cast request body - invalid data type" do
      conn = create_conn(%{"user" => %{"email" => 123}})

      assert {:error, errors} =
               Operation2.cast(
                 OperationFixtures.create_user(),
                 conn,
                 "application/json",
                 SpecModule.spec().components
               )

      assert [error] = errors
      assert %Error{} = error
      assert error.reason == :invalid_type
    end

    test "cast request body reference - invalid data type" do
      conn = put_conn(%{"user" => %{"email" => 123}})

      assert {:error, errors} =
               Operation2.cast(
                 OperationFixtures.update_user(),
                 conn,
                 "application/json",
                 SpecModule.spec().components
               )

      assert [error] = errors
      assert %Error{} = error
      assert error.reason == :invalid_type
    end

    test "casts valid query params and respects defaults" do
      valid_query_params = %{"name" => "Rubi", "age" => "31", "member" => "true"}
      assert {:ok, conn} = do_index_cast(valid_query_params)
      assert conn.params == %{age: 31, member: true, name: "Rubi", include_archived: false}
    end

    test "casts valid query params and overrides defaults" do
      valid_query_params = %{
        "name" => "Rubi",
        "age" => "31",
        "member" => "true",
        "include_archived" => "true"
      }

      assert {:ok, conn} = do_index_cast(valid_query_params)
      assert conn.params == %{age: 31, member: true, name: "Rubi", include_archived: true}
    end

    test "validate invalid data type for query param" do
      query_params = %{"age" => "asdf"}
      assert {:error, [error]} = do_index_cast(query_params)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.type == :integer
      assert error.value == "asdf"
    end

    test "validate missing required query param" do
      parameter =
        Operation.parameter(:name, :query, :string, "Filter by user name", required: true)

      operation = %{OperationFixtures.user_index() | parameters: [parameter]}

      assert {:error, [error]} = do_index_cast(%{}, operation: operation)
      assert %Error{} = error
      assert error.reason == :missing_field
      assert error.name == :name
    end

    test "validate missing content-type header for required requestBody" do
      conn = :post |> Plug.Test.conn("/api/users/") |> Plug.Conn.fetch_query_params()
      operation = OperationFixtures.create_user()

      assert {:error, [%Error{reason: :missing_header, name: "content-type"}]} =
               Operation2.cast(
                 operation,
                 conn,
                 nil,
                 SpecModule.spec().components
               )
    end

    test "validate invalid content-type header for required requestBody" do
      conn =
        create_conn(%{})
        |> Plug.Conn.put_req_header("content-type", "text/html")

      operation = OperationFixtures.create_user()

      assert {:error, [%Error{reason: :invalid_header, name: "content-type"}]} =
               Operation2.cast(
                 operation,
                 conn,
                 "text/html",
                 SpecModule.spec().components
               )
    end

    test "validate invalid content-type header for required requestBody reference" do
      conn =
        put_conn(%{})
        |> Plug.Conn.put_req_header("content-type", "text/html")

      operation = OperationFixtures.update_user()

      assert {:error, [%Error{reason: :invalid_header, name: "content-type"}]} =
               Operation2.cast(
                 operation,
                 conn,
                 "text/html",
                 SpecModule.spec().components
               )
    end

    test "validate invalid value for integer range" do
      parameter =
        Operation.parameter(
          :age,
          :query,
          %Schema{type: :integer, minimum: 1, maximum: 99},
          "Filter by user age",
          required: true
        )

      operation = %{OperationFixtures.user_index() | parameters: [parameter]}

      assert {:error, [error]} = do_index_cast(%{"age" => 100}, operation: operation)
      assert %Error{} = error
      assert error.reason == :maximum

      assert {:error, [error]} = do_index_cast(%{"age" => 0}, operation: operation)
      assert %Error{} = error
      assert error.reason == :minimum
    end

    test "validate not supported additional properties" do
      conn = create_conn(:get, "/api/users?unsupported_key=value")
      operation = OperationFixtures.user_index()

      expected_response =
        {:error,
         [
           %OpenApiSpex.Cast.Error{
             format: nil,
             length: 0,
             meta: %{},
             name: "unsupported_key",
             path: ["unsupported_key"],
             reason: :unexpected_field,
             type: nil,
             value: %{"unsupported_key" => "value"}
           }
         ]}

      assert expected_response ==
               Operation2.cast(
                 operation,
                 conn,
                 "text/html",
                 SpecModule.spec().components
               )
    end

    defp do_index_cast(query_params, opts \\ []) do
      conn =
        :get
        |> Plug.Test.conn("/api/users?" <> URI.encode_query(query_params))
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()
        |> build_params()

      operation = opts[:operation] || OperationFixtures.user_index()

      Operation2.cast(
        operation,
        conn,
        "application/json",
        SpecModule.spec().components
      )
    end

    defp create_conn(body_params) do
      create_conn(:post, "/api/users")
      |> Map.put(:body_params, body_params)
      |> build_params()
    end

    def create_conn(method, url) do
      method
      |> Plug.Test.conn(url)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.fetch_query_params()
    end

    defp put_conn(body_params) do
      create_conn(:put, "/api/users")
      |> Map.put(:body_params, body_params)
      |> build_params()
    end

    defp build_params(conn = %{body_params: params}) when is_list(params) do
      build_params(%{conn | body_params: %{"_json" => params}})
    end

    defp build_params(conn) do
      params =
        conn.path_params
        |> Map.merge(conn.query_params)
        |> Map.merge(conn.body_params)

      %{conn | params: params}
    end
  end
end
