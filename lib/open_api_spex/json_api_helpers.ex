defmodule OpenApiSpex.JsonApiHelpers do
  alias OpenApiSpex.JsonApiHelpers.{JsonApiDocument, JsonApiResource}
  alias OpenApiSpex.Schema

  def document_schema(%JsonApiDocument{} = document) do
    if not is_binary(document.title) do
      raise "%JsonApiDocument{} :title is required and must be a string"
    end

    resource = %{
      document.resource
      | title: document.resource.title || document.title <> "Resource"
    }

    resource_schema = %Schema{
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        type: %Schema{type: :string},
        attributes: attributes_schema(resource)
      },
      required: [:id, :type, :attributes],
      title: resource.title
    }

    %Schema{
      type: :object,
      properties: %{
        data: resource_schema
      },
      required: [:data],
      title: document.title <> "Document"
    }
  end

  def resource_schema(%JsonApiResource{} = resource) do
    if not is_binary(resource.title) do
      raise "%JsonApiResource{} :title is required and must be a string"
    end

    %Schema{
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        type: %Schema{type: :string},
        attributes: attributes_schema(resource)
      },
      required: [:id, :type],
      title: resource.title <> "Resource"
    }
  end

  def attributes_schema(%JsonApiResource{} = resource) do
    if not is_binary(resource.title) do
      raise "%JsonApiResource{} :title is required and must be a string"
    end

    %Schema{
      type: :object,
      properties: resource.properties,
      title: resource.title <> "Attributes"
    }
  end

  defmacro generate_document_schema(attrs) do
    quote do
      require OpenApiSpex

      @document struct!(OpenApiSpex.JsonApiHelpers.JsonApiDocument, unquote(attrs))
      def document, do: @document

      @document_schema OpenApiSpex.JsonApiHelpers.document_schema(@document)
      def document_schema, do: @document_schema

      OpenApiSpex.schema(@document_schema)
    end
  end

  defmacro document(attrs) do
    quote do
      @resource struct!(OpenApiSpex.JsonApiHelpers.JsonApiResource, unquote(attrs))
      def resource, do: @resource

      @resource_schema OpenApiSpex.JsonApiHelpers.resource_schema(@resource)
      def resource_schema, do: @resource_schema
    end
  end

  defmacro generate_resource_schema(attrs) do
    quote do
      require OpenApiSpex

      @resource struct!(OpenApiSpex.JsonApiHelpers.JsonApiResource, unquote(attrs))
      def resource, do: @resource

      @resource_schema OpenApiSpex.JsonApiHelpers.resource_schema(@resource)
      def resource_schema, do: @resource_schema

      OpenApiSpex.schema(@resource_schema)
    end
  end
end
