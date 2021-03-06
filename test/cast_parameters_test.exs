defmodule OpenApiSpex.CastParametersTest do
  use ExUnit.Case

  alias OpenApiSpex.{
    CastParameters,
    Components,
    MediaType,
    Operation,
    Parameter,
    Reference,
    Schema
  }

  describe "cast/3" do
    test "fails for unsupported additional properties " do
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

    test "casting of headers is case-insensitive" do
      conn = create_conn()
      operation = create_operation()
      components = create_components()

      {:ok, conn} = CastParameters.cast(conn, operation, components)

      assert %{params: %{"Content-Type": "application/json"}} = conn
    end

    test "cast style: form, explode: false query parameters" do
      size_schema = %Schema{
        type: :string,
        enum: [
          "XS",
          "S",
          "M",
          "L",
          "XL"
        ]
      }

      schema = %Schema{
        title: "SizeParams",
        type: :array,
        uniqueItems: true,
        minItems: 2,
        items: size_schema
      }

      parameter = %Parameter{
        in: :query,
        name: :sizes,
        required: true,
        style: :form,
        explode: false,
        schema: schema
      }

      operation = %Operation{
        parameters: [parameter],
        responses: %{
          200 => %Schema{type: :object}
        }
      }

      components = %Components{
        schemas: %{"SizeParams" => schema}
      }

      sizes_param = "S,M,L"

      conn =
        :get
        |> Plug.Test.conn("/api/t-shirts?sizes=#{sizes_param}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      assert {:ok, conn} = CastParameters.cast(conn, operation, components)
      assert %{params: %{sizes: ["S", "M", "L"]}} = conn
    end

    test "cast json query params" do
      schema = %Schema{
        type: :object,
        title: "FilterParams",
        properties: %{
          size: %Schema{type: :string, pattern: "^XS|S|M|L|XL$"},
          color: %Schema{type: :string}
        }
      }

      parameter = %Parameter{
        in: :query,
        name: :filter,
        required: false,
        content: %{
          "application/json" => %MediaType{
            schema: %Reference{"$ref": "#/components/schemas/FilterParams"}
          }
        }
      }

      operation = %Operation{
        parameters: [parameter],
        responses: %{
          200 => %Schema{type: :object}
        }
      }

      components = %Components{
        schemas: %{"FilterParams" => schema}
      }

      filter_json =
        %{size: "S", color: "blue"}
        |> Jason.encode!()
        |> URI.encode()

      conn =
        :get
        |> Plug.Test.conn("/api/users?filter=#{filter_json}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      # Referencing issue: https://github.com/open-api-spex/open_api_spex/issues/349
      # Ideally, this would be a successful cast, the JSON parameter would be decoded as
      # part of the casting process. However, that behavior is not yet supported.
      CastParameters.cast(conn, operation, components)
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
