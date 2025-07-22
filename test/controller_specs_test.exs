defmodule OpenApiSpex.ControllerSpecsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias OpenApiSpex.{MediaType, RequestBody, Response}
  alias OpenApiSpexTest.DslController
  alias OpenApiSpexTest.DslControllerOperationStructs

  describe "operation/2" do
    test "supports :parameters" do
      assert %OpenApiSpex.Operation{
               responses: %{},
               summary: "Update user",
               parameters: update_parameters
             } = DslController.open_api_operation(:update)

      assert [
               %OpenApiSpex.Parameter{
                 description: "User ID",
                 example: 1001,
                 in: :path,
                 name: :id,
                 required: true,
                 schema: %OpenApiSpex.Schema{type: :integer}
               }
             ] = update_parameters
    end

    test ":request_body" do
      assert %OpenApiSpex.Operation{
               summary: "Update user",
               requestBody: request_body
             } = DslController.open_api_operation(:update)

      assert %RequestBody{
               content: %{"application/json" => media_type},
               description: "User params"
             } = request_body

      assert %MediaType{schema: OpenApiSpexTest.DslController.UserParams} = media_type
      assert media_type.example == "json example"

      assert text_media_type = request_body.content["application/text"]
      assert text_media_type.example == "text example"
    end

    test ":responses" do
      assert %OpenApiSpex.Operation{
               summary: "Update user",
               responses: responses
             } = DslController.open_api_operation(:update)

      assert %{200 => response} = responses

      assert %Response{
               content: content,
               description: "User response",
               headers: %{"content-type" => %OpenApiSpex.Header{}}
             } = response

      assert %{"application/json" => media_type} = content
      assert %MediaType{schema: OpenApiSpexTest.DslController.UserResponse} = media_type
      assert media_type.example == "json example"

      assert %{"application/text" => media_type} = content
      assert media_type.example == "text example"
    end

    test "supports Parameter, RequestBody and Response structs" do
      assert %OpenApiSpex.Operation{
               summary: "Update user",
               requestBody: request_body,
               responses: responses
             } = DslControllerOperationStructs.open_api_operation(:update)

      assert %{200 => response} = responses

      assert %Response{
               content: content,
               description: "User response",
               headers: %{"content-type" => %OpenApiSpex.Header{}}
             } = response

      assert %{
               "application/json" => %MediaType{
                 schema: OpenApiSpexTest.DslController.UserResponse,
                 example: "json example response"
               },
               "application/text" => %MediaType{
                 schema: OpenApiSpexTest.DslController.UserResponse,
                 example: "text example response"
               }
             } = content

      assert %RequestBody{
               content: %{
                 "application/json" => %MediaType{
                   schema: OpenApiSpexTest.DslController.UserParams,
                   example: "json example request"
                 },
                 "application/text" => %MediaType{
                   schema: OpenApiSpexTest.DslController.UserParams,
                   example: "text example request"
                 }
               },
               description: "User params"
             } = request_body
    end

    test ":deprecated" do
      assert %OpenApiSpex.Operation{
               summary: "User destroy",
               deprecated: true
             } = DslController.open_api_operation(:destroy)
    end

    test ":external_docs" do
      assert %OpenApiSpex.Operation{
               summary: "User destroy",
               externalDocs: %OpenApiSpex.ExternalDocumentation{
                 description: "User destroy docs",
                 url: "https://example.com/"
               }
             } = DslController.open_api_operation(:destroy)
    end

    test "outputs warning when action not defined for called open_api_operation" do
      output = capture_io(:stderr, fn -> DslController.open_api_operation(:undefined) end)

      assert output =~
               ~r/warning:.*No operation spec defined for controller action OpenApiSpexTest.DslController.undefined/
    end

    test "merging shared a op-specific tags" do
      assert %OpenApiSpex.Operation{
               tags: tags
             } = DslController.open_api_operation(:update)

      assert tags == ["users", "custom"]
    end

    test "merging shared a op-specific security" do
      assert %OpenApiSpex.Operation{
               security: security
             } = DslController.open_api_operation(:update)

      assert security == [%{"api_key" => ["mySecurityScheme"]}, %{"two" => ["another"]}]
    end

    test "second operation is defined" do
      assert %OpenApiSpex.Operation{operationId: "OpenApiSpexTest.DslController.index"} =
               DslController.open_api_operation(:index)
    end

    test "supports extensions" do
      assert %OpenApiSpex.Operation{extensions: %{"x-foo" => "bar"}} =
               DslController.open_api_operation(:index)
    end

    test "raises when unknown key is provided" do
      msg =
        "Unknown keys given to operation/2: [:unknown]. Allowed keys are: " <>
          "[:callbacks, :description, :deprecated, :external_docs, :operation_id, :parameters, " <>
          ":request_body, :responses, :security, :summary, :tags], and keys starting with 'x-'."

      assert_raise ArgumentError, msg, fn ->
        Code.eval_string("""
        defmodule TestController do
          use OpenApiSpex.ControllerSpecs

          operation :index,
            summary: "Users index",
            parameters: [
              username: [
                in: :query,
                description: "Filter by username",
                type: :string
              ]
            ],
            responses: [
              ok: {"Users index response", "application/json", UsersIndexResponse}
            ],
            unknown: "value",
            "x-foo": "bar"

          def index(conn, _) do
            json(conn, [])
          end
        end
        """)
      end
    end
  end
end
