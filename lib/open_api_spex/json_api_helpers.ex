defmodule OpenApiSpex.JsonApiHelpers do
  alias OpenApiSpex.JsonApiHelpers.{JsonApiDocument, JsonApiResource}

  def document_schema(document) do
    JsonApiDocument.schema(document)
  end

  def resource_schema(resource) do
    JsonApiResource.schema(resource)
  end

  defmacro generate_document_schema(attrs) do
    quote do
      require OpenApiSpex

      @document struct!(JsonApiDocument, unquote(attrs))
      def document, do: @document

      @document_schema JsonApiDocument.schema(@document)
      def document_schema, do: @document_schema

      OpenApiSpex.schema(@document_schema)
    end
  end

  defmacro generate_resource_schema(attrs) do
    quote do
      require OpenApiSpex

      @resource struct!(JsonApiResource, unquote(attrs))
      def resource, do: @resource

      @resource_schema JsonApiResource.schema(@resource)
      def resource_schema, do: @resource_schema

      OpenApiSpex.schema(@resource_schema)
    end
  end
end
