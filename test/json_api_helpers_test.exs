defmodule OpenApiSpex.JsonApiHelpersTest do
  use ExUnit.Case, async: true

  alias OpenApiSpexTest.{CartDocument, CartIndexDocument, CartResource}
  alias OpenApiSpex.{JsonApiHelpers, Schema}
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource

  describe "generate_resource_document/1" do
    test "generate schema/0" do
      assert %Schema{} = schema = CartDocument.schema()
      assert schema.title == "CartDocument"
      assert %{data: _} = schema.properties
      assert schema.properties.data.title == CartResource.schema().title
    end

    test "generate schema for index document" do
      assert %Schema{} = schema = CartIndexDocument.schema()
      assert schema.title == "CartIndexDocument"
      assert %{data: _} = schema.properties
      assert schema.properties.data.type == :array
      assert schema.properties.data.items.title == "CartResource"
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
