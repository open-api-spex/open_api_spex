defmodule OpenApiSpex.JsonApiHelpers do
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource
  alias OpenApiSpex.Schema

  def document_schema(%JsonApiResource{} = resource) do
    if not is_binary(resource.title) do
      raise "%JsonApiResource{} :title is required and must be a string"
    end

    %Schema{
      type: :object,
      properties: %{
        data: resource_schema(resource)
      },
      required: [:data],
      title: resource.title <> "Document"
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

      @resource struct!(OpenApiSpex.JsonApiHelpers.JsonApiResource, unquote(attrs))
      def resource, do: @resource

      @document_schema OpenApiSpex.JsonApiHelpers.document_schema(@resource)
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
