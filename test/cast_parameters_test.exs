defmodule OpenApiSpex.CastParametersTest do
  use ExUnit.Case
  alias OpenApiSpex.{Operation, Schema, Components, CastParameters}

  describe "cast/3" do
    test "fails for not supported additional properties " do
      conn = create_conn_with_unexpected_path_param()
      operation = create_operation()
      components = create_empty_components()

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
      components = create_empty_components()
      {:ok, conn} = CastParameters.cast(conn, operation, components)
      assert %{params: %{includeInactive: false}} = conn
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
        )
      ],
      responses: %{
        200 => %Schema{type: :object}
      }
    }
  end

  defp create_empty_components() do
    %Components{}
  end
end
