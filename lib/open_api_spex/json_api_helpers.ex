defmodule OpenApiSpex.JsonApiHelpers do
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource
  alias OpenApiSpex.Schema

  def resource_schema(%JsonApiResource{} = resource) do
    if not is_binary(resource.title) do
      raise "%JsonApiResource{} :title is required and must be a string"
    end

    %Schema{
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
      properties: resource.properties,
      title: resource.title <> "Attributes"
    }
  end
end
