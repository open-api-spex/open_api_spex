defmodule OpenApiSpex.OpenApi.DecodeTest do
  use ExUnit.Case
  use Plug.Test

  alias OpenApiSpex.OpenApi

  describe "OpenApiSpex.OpenApi.Decode.decode/1" do
    test "OpenApi" do
      # NOTE: This test could be split into many smaller tests, that is the goal!
      # TODO: Move the spec to a setup below, where we could easily try a yaml version also
      spec =
        "./test/support/encoded_schema.json"
        |> File.read!()
        |> Jason.decode!()
        |> OpenApiSpex.OpenApi.Decode.decode()

      assert %OpenApi{
               openapi: openapi,
               info: info,
               servers: servers,
               paths: paths,
               components: components,
               security: security,
               tags: tags,
               externalDocs: externalDocs,
               extensions: extensions
             } = spec

      assert "3.0.0" == openapi

      assert %OpenApiSpex.Info{
               title: _title,
               version: _version,
               description: _description,
               contact: contact,
               license: license,
               extensions: info_extensions
             } = info

      assert %OpenApiSpex.Contact{} = contact

      assert %OpenApiSpex.License{} = license

      assert info_extensions == %{"x-extension" => "foo"}

      assert %{"x-extension" => %{"value" => "haha"}} == extensions

      assert %OpenApiSpex.ExternalDocumentation{
               description: _,
               url: _
             } = externalDocs

      assert %OpenApiSpex.Components{
               callbacks: callbacks,
               schemas: schemas,
               responses: responses,
               examples: examples,
               links: %{
                 "address" => link
               },
               requestBodies: requestBodies,
               parameters: %{
                 "AcceptEncodingHeader" => components_parameters_parameter
               },
               securitySchemes: securitySchemes,
               headers: %{
                 "api-version" => components_headers_header
               }
             } = components

      assert %{
               "test" => %OpenApiSpex.RequestBody{
                 description: "user to add to the system",
                 content: %{
                   "application/json" => media_type
                 },
                 required: false
               }
             } = requestBodies

      assert %OpenApiSpex.MediaType{
               schema: %OpenApiSpex.Reference{
                 "$ref": "#/components/schemas/User"
               },
               examples: %{
                 "user" => %OpenApiSpex.Example{
                   externalValue: "http://foo.bar/examples/user-example.json",
                   summary: "User Example",
                   value: nil,
                   description: nil
                 }
               },
               encoding: %{
                 "historyMetadata" => %OpenApiSpex.Encoding{
                   contentType: "application/xml; charset=utf-8",
                   style: :form,
                   explode: false,
                   allowReserved: false,
                   headers: %{
                     "X-Rate-Limit-Limit" => %OpenApiSpex.Header{
                       description: "The number of allowed requests in the current period",
                       schema: %OpenApiSpex.Schema{
                         type: :integer
                       }
                     }
                   }
                 }
               },
               example: nil
             } = media_type

      assert %{
               "componentCallback" => componentCallback
             } = callbacks

      assert %{
               "http://server-b.com?transactionId={$request.body#/id}" => %OpenApiSpex.PathItem{}
             } = componentCallback

      assert %{
               "NotFound" => %OpenApiSpex.Response{
                 headers: %{
                   "X-Rate-Limit-Limit" => %OpenApiSpex.Header{
                     description: "The number of allowed requests in the current period",
                     schema: %OpenApiSpex.Schema{
                       type: :integer
                     }
                   }
                 },
                 content: %{
                   "application/json" => %OpenApiSpex.MediaType{
                     schema: %OpenApiSpex.Schema{
                       type: :string,
                       maxLength: 10
                     }
                   }
                 },
                 links: %{
                   "test" => %OpenApiSpex.Link{
                     operationId: "response-link-test"
                   }
                 },
                 description: "Entity not found."
               }
             } == responses

      assert %{
               "foo" => %OpenApiSpex.Example{}
             } = examples

      assert %OpenApiSpex.Parameter{
               description: nil,
               name: :"accept-encoding",
               in: :header,
               required: false,
               allowEmptyValue: true,
               schema: %OpenApiSpex.Schema{
                 example: "gzip",
                 type: :string
               },
               extensions: %{"x-extension" => "foo"}
             } == components_parameters_parameter

      assert %{
               "User" => user_schema,
               "Admin" => admin_schema
             } = schemas

      assert %OpenApiSpex.Schema{
               allOf: [
                 %OpenApiSpex.Reference{
                   "$ref": "#/components/schemas/User"
                 },
                 %OpenApiSpex.Reference{
                   "$ref": "#/components/schemas/SpecialUser"
                 }
               ],
               discriminator: %OpenApiSpex.Discriminator{
                 propertyName: "userType"
               }
             } == admin_schema

      assert %OpenApiSpex.Schema{
               nullable: false,
               readOnly: false,
               writeOnly: false,
               deprecated: false,
               example: %{},
               externalDocs: %OpenApiSpex.ExternalDocumentation{
                 description: "Find more info here",
                 url: "https://example.com"
               },
               properties: %{
                 first_name: %OpenApiSpex.Schema{
                   xml: %OpenApiSpex.Xml{
                     namespace: "http://example.com/schema/sample",
                     prefix: "sample"
                   }
                 },
                 metadata: %OpenApiSpex.Schema{
                   properties: %{},
                   type: :object,
                   additionalProperties: %OpenApiSpex.Reference{
                     "$ref": "#/components/schemas/MetadataObject"
                   }
                 }
               }
             } = user_schema

      assert %OpenApiSpex.Link{
               description: nil,
               operationRef: nil,
               operationId: "test",
               requestBody: %OpenApiSpex.RequestBody{
                 description: "link payload",
                 content: %{
                   "application/json" => %OpenApiSpex.MediaType{
                     schema: %OpenApiSpex.Schema{}
                   }
                 }
               },
               parameters: %{
                 "ContentTypeHeader" => %OpenApiSpex.Reference{
                   "$ref": "#/components/parameters/ContentTypeHeader"
                 }
               },
               server: %OpenApiSpex.Server{
                 description: "Development server",
                 url: "https://development.gigantic-server.com/v1",
                 variables: %{}
               }
             } == link

      assert %{
               "api_key" => api_key_security_scheme,
               "petstore_auth" => petstore_auth_security_scheme
             } = securitySchemes

      assert %OpenApiSpex.SecurityScheme{
               flows: oauth_flows
             } = petstore_auth_security_scheme

      assert %OpenApiSpex.SecurityScheme{
               extensions: %{"x-extension" => "foo"}
             } = api_key_security_scheme

      assert %OpenApiSpex.OAuthFlows{
               implicit: oauth_flow
             } = oauth_flows

      assert %OpenApiSpex.OAuthFlow{
               authorizationUrl: "http://example.org/api/oauth/dialog",
               tokenUrl: nil,
               refreshUrl: nil,
               scopes: %{
                 "read:pets" => "read your pets",
                 "write:pets" => "modify pets in your account"
               }
             } = oauth_flow

      assert %OpenApiSpex.Header{
               description: "The version of the api to be used",
               schema: %OpenApiSpex.Schema{
                 type: :string,
                 enum: ["beta"]
               }
             } == components_headers_header

      assert [server] = servers

      assert %OpenApiSpex.Server{
               description: "Development server",
               url: "https://development.gigantic-server.com/v1",
               variables: serverVariables
             } = server

      assert %{
               "username" => %OpenApiSpex.ServerVariable{
                 default: "demo",
                 description:
                   "this value is assigned by the service provider, in this example `gigantic-server.com`",
                 enum: nil
               }
             } = serverVariables

      assert [tag] = tags

      assert %OpenApiSpex.Tag{
               extensions: %{"x-extension" => "foo"},
               description: "Pets operations",
               externalDocs: %OpenApiSpex.ExternalDocumentation{
                 description: "Find more info here",
                 url: "https://example.com"
               },
               name: "pet"
             } == tag

      assert [
               %{
                 "petstore_auth" => ["write:pets", "read:pets"]
               }
             ] == security

      assert %{
               "/example" => %OpenApiSpex.PathItem{
                 summary: "/example summary",
                 description: "/example description",
                 extensions: %{"x-extension" => "foo"},
                 servers: [%OpenApiSpex.Server{}],
                 parameters: [
                   %OpenApiSpex.Reference{
                     "$ref": "#/components/parameters/ContentTypeHeader"
                   }
                 ],
                 post: %OpenApiSpex.Operation{
                   extensions: %{"x-extension" => "foo"},
                   parameters: [
                     %OpenApiSpex.Reference{},
                     %OpenApiSpex.Reference{},
                     %OpenApiSpex.Parameter{}
                   ],
                   deprecated: false,
                   operationId: "example-post-test",
                   requestBody: requestBody,
                   callbacks: operationCallbacks,
                   responses: operationResponses,
                   security: operationSecurity,
                   tags: ["test"],
                   summary: "/example post summary",
                   description: "/example post description",
                   externalDocs: %OpenApiSpex.ExternalDocumentation{
                     description: "Find more info here",
                     url: "https://example.com"
                   }
                 },
                 patch: %OpenApiSpex.Operation{
                   parameters: [],
                   deprecated: false,
                   operationId: "example-patch-test",
                   requestBody: %OpenApiSpex.Reference{
                     "$ref": "#/components/requestBodies/test"
                   },
                   callbacks: %{},
                   responses: operationResponses,
                   security: operationSecurity,
                   tags: ["test"],
                   summary: "/example patch summary",
                   description: "/example patch description"
                 }
               }
             } = paths

      assert [
               %{
                 "petstore_auth" => ["write:pets"]
               }
             ] == operationSecurity

      assert %{
               "200" => %OpenApiSpex.Response{
                 extensions: %{"x-extension" => "foo"}
               }
             } = operationResponses

      assert %{
               "operationCallback" => %{
                 "http://server-a.com?transactionId={$request.body#/id}" => %OpenApiSpex.PathItem{}
               }
             } = operationCallbacks

      assert %OpenApiSpex.Schema{
               properties: properties
             } =
               get_in(
                 requestBody,
                 [:content, "application/json", :schema]
                 |> Enum.map(&Access.key/1)
               )

      passengers =
        get_in(
          properties,
          [:data, :properties, :passengers]
          |> Enum.map(&Access.key/1)
        )

      assert %OpenApiSpex.Schema{} = passengers

      assert %OpenApiSpex.Schema{
               type: :string,
               enum: ["adult", "child"]
             } =
               get_in(
                 passengers,
                 [:items, :properties, :type]
                 |> Enum.map(&Access.key/1)
               )

      test_conn =
        conn(:post, "/example?myParam=1", %{
          "data" => %{
            "first_name" => "Bob",
            "given_name" => "Builder",
            "phone_number" => "+441111111111"
          }
        })
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept-encoding", "gzip")

      test_conn = fetch_query_params(test_conn)

      assert {:ok, _validation_result} =
               OpenApiSpex.cast_and_validate(
                 spec,
                 spec.paths["/example"].post,
                 test_conn
               )
    end
  end
end
