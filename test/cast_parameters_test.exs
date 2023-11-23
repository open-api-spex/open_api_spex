defmodule OpenApiSpex.CastParametersTest do
  use ExUnit.Case

  require IEx

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
      spec = spec_with_components()

      cast_result = CastParameters.cast(conn, operation, spec)

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
      spec = spec_with_components()
      {:ok, conn} = CastParameters.cast(conn, operation, spec)
      assert %{params: %{includeInactive: false}} = conn
    end

    test "casting of headers is case-insensitive" do
      conn = create_conn()
      operation = create_operation()
      spec = spec_with_components()

      {:ok, conn} = CastParameters.cast(conn, operation, spec)

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

      spec =
        spec_with_components(%Components{
          schemas: %{"SizeParams" => schema}
        })

      sizes_param = "S,M,L"

      conn =
        :get
        |> Plug.Test.conn("/api/t-shirts?sizes=#{sizes_param}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      assert {:ok, conn} = CastParameters.cast(conn, operation, spec)
      assert %{params: %{sizes: ["S", "M", "L"]}} = conn
    end

    test "cast json query params with default parser" do
      {operation, spec} = json_query_spec_operation()

      filter_json =
        %{size: "S", color: "blue"}
        |> Jason.encode!()
        |> URI.encode()

      conn =
        :get
        |> Plug.Test.conn("/api/users?filter=#{filter_json}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      assert {:ok, conn} = CastParameters.cast(conn, operation, spec)
      assert %{params: %{filter: %{size: "S", color: "blue"}}} = conn
    end

    test "cast json query params with custom parser" do
      {operation, spec} = json_query_spec_operation("custom/json")

      spec =
        OpenApiSpex.add_parameter_content_parser(
          spec,
          "custom/json",
          OpenApiSpex.OpenApi.json_encoder()
        )

      filter_json =
        %{size: "S", color: "blue"}
        |> Jason.encode!()
        |> URI.encode()

      conn =
        :get
        |> Plug.Test.conn("/api/users?filter=#{filter_json}")
        |> Plug.Conn.put_req_header("content-type", "custom/json")
        |> Plug.Conn.fetch_query_params()

      assert {:ok, conn} = CastParameters.cast(conn, operation, spec)
      assert %{params: %{filter: %{size: "S", color: "blue"}}} = conn
    end

    test "cast json query params with custom parser with regex" do
      {operation, spec} = json_query_spec_operation("custom/json")

      spec =
        OpenApiSpex.add_parameter_content_parser(
          spec,
          ~r/custom\/.+/,
          fn string -> OpenApiSpex.OpenApi.json_encoder().decode(string) end
        )

      filter_json =
        %{size: "S", color: "blue"}
        |> Jason.encode!()
        |> URI.encode()

      conn =
        :get
        |> Plug.Test.conn("/api/users?filter=#{filter_json}")
        |> Plug.Conn.put_req_header("content-type", "custom/json")
        |> Plug.Conn.fetch_query_params()

      assert {:ok, conn} = CastParameters.cast(conn, operation, spec)
      assert %{params: %{filter: %{size: "S", color: "blue"}}} = conn
    end

    test "cast json query params with invalid json" do
      {operation, spec} = json_query_spec_operation()

      filter_json = URI.encode("{\"size\": \"S\", \"color: \"blue\"}")

      conn =
        :get
        |> Plug.Test.conn("/api/users?filter=#{filter_json}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      assert {:error,
              [%OpenApiSpex.Cast.Error{format: "application/json", reason: :invalid_format}]} =
               CastParameters.cast(conn, operation, spec)
    end

    test "cast param with oneof and valid args" do
      {operation, spec} = oneof_query_spec_operation()

      filter_params = URI.encode_query(%{size: "XL"})

      conn =
        :get
        |> Plug.Test.conn("/api/users?#{filter_params}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.fetch_query_params()

      # require IEx
      # IEx.pry()

      assert {:ok, _} = CastParameters.cast(conn, operation, spec)
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

  defp spec_with_components(components \\ nil) do
    %OpenApiSpex.OpenApi{
      info: %OpenApiSpex.Info{title: "Spec", version: "1.0.0"},
      paths: [],
      components: components || create_components()
    }
  end

  defp json_query_spec_operation(content_type \\ "application/json") do
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
        content_type => %MediaType{
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

    spec =
      spec_with_components(%Components{
        schemas: %{"FilterParams" => schema}
      })

    {operation, spec}
  end

  defp oneof_query_spec_operation() do
    schema = %Schema{
      type: :object,
      title: "Filters",
      oneOf: [
        %Schema{
          type: :object,
          properties: %{
            size: %Schema{type: :string, pattern: "^XS|S|M|L|XL$"},
            color: %Schema{type: :string}
          },
          required: [:size]
        },
        %Schema{
          type: :object,
          properties: %{
            size: %Schema{type: :string, pattern: "^XS|S|M|L|XL$"},
            color: %Schema{type: :string}
          },
          required: [:color]
        }
      ],
      example: %{size: "XL"}
    }

    parameter = %Parameter{
      in: :query,
      name: :filter,
      required: false,
      schema: %Reference{"$ref": "#/components/schemas/Filters"},
      explode: true,
      style: :form,
      required: true
    }

    operation = %Operation{
      parameters: [parameter],
      responses: %{
        200 => %Schema{type: :object}
      }
    }

    spec =
      spec_with_components(%Components{
        schemas: %{"Filters" => schema}
      })

    {operation, spec}
  end
end
