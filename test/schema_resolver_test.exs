defmodule OpenApiSpex.SchemaResolverTest do
  use ExUnit.Case

  alias OpenApiSpex.{
    Info,
    MediaType,
    OpenApi,
    Operation,
    PathItem,
    Reference,
    RequestBody,
    Response,
    Schema
  }

  test "Resolves schemas in OpenApi spec" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/api/users" => %PathItem{
          get: %Operation{
            responses: %{
              200 => %Response{
                description: "Success",
                content: %{
                  "application/json" => %MediaType{
                    schema: OpenApiSpexTest.Schemas.UsersResponse
                  }
                }
              }
            }
          },
          post: %Operation{
            description: "Create a user",
            operationId: "UserController.create",
            requestBody: %RequestBody{
              content: %{
                "application/json" => %MediaType{
                  schema: OpenApiSpexTest.Schemas.UserRequest
                }
              }
            },
            responses: %{
              201 => %Response{
                description: "Created",
                content: %{
                  "application/json" => %MediaType{
                    schema: OpenApiSpexTest.Schemas.UserResponse
                  }
                }
              }
            }
          }
        },
        "/api/users/{id}/payment_details" => %PathItem{
          get: %Operation{
            responses: %{
              200 => %Response{
                description: "Success",
                content: %{
                  "application/json" => %MediaType{
                    schema: OpenApiSpexTest.Schemas.PaymentDetails
                  }
                }
              }
            }
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    assert %Reference{"$ref": "#/components/schemas/UsersResponse"} =
             resolved.paths["/api/users"].get.responses[200].content["application/json"].schema

    assert %Reference{"$ref": "#/components/schemas/UserResponse"} =
             resolved.paths["/api/users"].post.responses[201].content["application/json"].schema

    assert %Reference{"$ref": "#/components/schemas/UserRequest"} =
             resolved.paths["/api/users"].post.requestBody.content["application/json"].schema

    assert %{
             "UserRequest" => %Schema{},
             "UserResponse" => %Schema{},
             "User" => %Schema{},
             "PaymentDetails" => %Schema{},
             "CreditCardPaymentDetails" => %Schema{},
             "DirectDebitPaymentDetails" => %Schema{}
           } = resolved.components.schemas
  end
end
