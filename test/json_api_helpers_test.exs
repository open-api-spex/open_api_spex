defmodule OpenApiSpex.JsonApiHelpersTest do
  use ExUnit.Case, async: true

  alias OpenApiSpexTest.JsonApiSchemas.{
    CartResource,
    CartDocument,
    CartPaginatedDocument,
    CartListDocument
  }

  alias OpenApiSpex.{JsonApiHelpers, Schema}
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource

  # describe "from operation specs" do
  #   test "index action" do
  #     spec = OpenApiSpexTest.ApiSpec.spec()
  #     assert %Schema{} = _schema = spec.components.schemas["CartAnnotatedDocument"]
  #   end
  # end

  describe "generate_resource_document/1" do
    test "generate schema/0" do
      assert %Schema{} = schema = CartDocument.schema()
      assert schema.title == "CartDocument"
      assert %{data: _} = schema.properties
      assert schema.properties.data.schema().title == CartResource.schema().title
    end

    test "generate schema for index document" do
      assert %Schema{} = schema = CartListDocument.schema()
      assert schema.title == "CartListDocument"
      assert %{data: _} = schema.properties
      assert schema.properties.data.type == :array
      assert schema.properties.data.items == CartResource
    end

    test "generate schema for paginated document" do
      assert %Schema{} = schema = CartPaginatedDocument.schema()
      assert schema.title == "CartPaginatedDocument"
      assert %{data: _} = schema.properties
      assert schema.properties.data.type == :array
      assert schema.properties.data.items == CartResource

      # Check for meta fields
      assert %{links: links} = schema.properties
      assert links.properties.first.type == :string
      assert links.properties.last.type == :string
      assert links.properties.prev.type == :string
      assert links.properties.next.type == :string
    end
  end

  describe "generate_resource_schema/1" do
    test "generate resource/0 and resource_schema/0" do
      assert %JsonApiResource{} = CartResource.resource()
      assert %Schema{} = schema = CartResource.schema()
      assert schema.title == "CartResource"
    end
  end

  describe "resource_schema/1" do
    test "attributes" do
      resource = CartResource.resource()
      schema = JsonApiHelpers.resource_schema(resource)
      assert schema.properties.attributes == JsonApiResource.attributes_schema(resource)
      assert %Schema{} = schema.properties.id
      assert %Schema{} = schema.properties.type
    end

    test "title" do
      resource = CartResource.resource()
      schema = JsonApiHelpers.resource_schema(resource)
      assert schema.title == "CartResource"
    end
  end

  describe "attributes_schema/1" do
    test "generates schema with same properties" do
      resource = CartResource.resource()
      schema = JsonApiResource.attributes_schema(resource)
      assert schema.properties == resource.properties
    end

    test "generates title" do
      resource = CartResource.resource()
      schema = JsonApiResource.attributes_schema(resource)
      assert schema.title == "CartAttributes"
    end

    test ":title must be a string" do
      resource = CartResource.resource()
      resource = %{resource | title: nil}

      assert_raise(
        RuntimeError,
        "%JsonApiResource{} :title is required and must be a string",
        fn ->
          JsonApiResource.attributes_schema(resource)
        end
      )
    end
  end
end
