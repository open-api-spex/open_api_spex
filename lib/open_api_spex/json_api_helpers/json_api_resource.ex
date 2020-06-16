defmodule OpenApiSpex.JsonApiHelpers.JsonApiResource do
  alias OpenApiSpex.Schema

  defstruct additionalProperties: nil,
            properties: %{},
            required: [],
            title: nil

  def schema(resource) when is_atom(resource) and not is_nil(resource) do
    resource.schema()."x-struct"
  end

  def schema(%__MODULE__{} = resource) do
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

  def attributes_schema(%__MODULE__{} = resource) do
    if not is_binary(resource.title) do
      raise "%JsonApiResource{} :title is required and must be a string"
    end

    %Schema{
      type: :object,
      properties: resource.properties,
      title: resource.title <> "Attributes"
    }
  end
end
