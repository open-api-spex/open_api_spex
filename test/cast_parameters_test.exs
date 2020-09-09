defmodule OpenApiSpex.CastParametersTest do
  use ExUnit.Case
  alias OpenApiSpex.{Operation, Schema, Components, CastParameters, Reference}

  describe "cast/3" do
    test "fails for not supported additional properties " do
      conn = create_conn_with_unexpected_path_param()
      operation = create_operation()
      components = create_components()

      cast_result = CastParameters.cast(conn, operation, components)

      expected_response =
        {:error,
         [
           %OpenApiSpex.Cast.Error{
             format: nil,
             length: 0,
             meta: %{},
             name: "invalid_key",
             path: ["invalid_key"],
             reason: :unexpected_field,
             type: nil,
             value: %{"invalid_key" => "value"}
           }
         ]}

      assert expected_response == cast_result
    end

    test "default parameter values are supplied" do
      conn = create_conn()
      operation = create_operation()
      components = create_components()
      {:ok, conn} = CastParameters.cast(conn, operation, components)
      assert %{params: %{includeInactive: false}} = conn
    end

    test "casting of headers is not case sensitive" do
      conn = create_conn()
      operation = create_operation()
      components = create_components()

      {:ok, conn} = CastParameters.cast(conn, operation, components)

      assert %{params: %{"Content-Type": "application/json"}} = conn
    end
  end

  defp create_conn() do
    :get
    |> Plug.Test.conn("/api/users/")
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.fetch_query_params()
  end

  defp create_conn_with_unexpected_path_param() do
    :get
    |> Plug.Test.conn("/api/users?invalid_key=value")
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.fetch_query_params()
  end

  defp create_operation() do
    %Operation{
      parameters: [
        Operation.parameter(:id, :query, :string, "User ID", example: "1"),
        Operation.parameter(
          :includeInactive,
          :query,
          %Schema{type: :boolean, default: false},
          "Include inactive users"
        ),
        %Reference{"$ref": "#/components/parameters/Content-Type"}
      ],
      responses: %{
        200 => %Schema{type: :object}
      }
    }
  end

  defp create_components() do
    %Components{
      parameters: %{
        "Content-Type" => %OpenApiSpex.Parameter{
          allowEmptyValue: nil,
          allowReserved: nil,
          content: nil,
          deprecated: nil,
          description: "description",
          example: nil,
          examples: nil,
          explode: nil,
          in: :header,
          name: :"Content-Type",
          required: nil,
          schema: %OpenApiSpex.Schema{
            enum: ["application/json"],
            example: "application/json",
            type: :string
          },
          style: nil
        }
      }
    }
  end
end
