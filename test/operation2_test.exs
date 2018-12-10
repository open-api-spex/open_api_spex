defmodule OpenApiSpex.Operation2Test do
  use ExUnit.Case
  alias OpenApiSpex.{Operation, Operation2, Schema}
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

  defmodule OperationFixtures do
    @user_index %Operation{
      operationId: "UserController.index",
      parameters: [
        Operation.parameter(:name, :query, :string, "Filter by user name"),
        Operation.parameter(:age, :query, :integer, "User's age")
      ],
      responses: %{
        200 => Operation.response("User", "application/json", SchemaFixtures.user())
      }
    }

    def user_index, do: @user_index

    @create_user %Operation{
      operationId: "UserController.create",
      requestBody:
        Operation.request_body("request body", "application/json", SchemaFixtures.user(),
          required: true
        ),
      responses: %{
        200 => Operation.response("User list", "application/json", SchemaFixtures.user_list())
      }
    }

    def create_user, do: @create_user
  end

  defmodule SpecModule do
    def spec do
      paths = %{
        "/users" => %{
          "post" => OperationFixtures.create_user()
        }
      }

      %OpenApiSpex.OpenApi{
        info: nil,
        paths: paths,
        components: %{
          schemas: SchemaFixtures.schemas()
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
                 SchemaFixtures.schemas()
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
                 SchemaFixtures.schemas()
               )

      assert [error] = errors
      assert %Error{} = error
      assert error.reason == :invalid_type
    end

    test "validate undefined query param name" do
      query_params = %{"unknown" => "asdf"}

      assert {:error, [error]} = do_index_cast(query_params)

      assert %Error{} = error
      assert error.reason == :unexpected_field
      assert error.name == "unknown"
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

    defp do_index_cast(query_params, opts \\ []) do
      conn =
        :get
        |> Plug.Test.conn("/api/users?" <> URI.encode_query(query_params))
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      operation = opts[:operation] || OperationFixtures.user_index()

      Operation2.cast(
        operation,
        conn,
        "application/json",
        SchemaFixtures.schemas()
      )
    end

    defp create_conn(body_params) do
      :post
      |> Plug.Test.conn("/api/users")
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.fetch_query_params()
      |> Map.put(:body_params, body_params)
    end
  end
end
