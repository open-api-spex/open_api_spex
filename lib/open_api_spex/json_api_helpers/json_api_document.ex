defmodule OpenApiSpex.JsonApiHelpers.JsonApiDocument do
  alias OpenApiSpex.Schema
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource

  defstruct resource: nil,
            multiple: false,
            title: nil

  def schema(%__MODULE__{} = document) do
    if not is_binary(document.title) do
      raise "%JsonApiDocument{} :title is required and must be a string"
    end

    resource = document.resource
    resource_item_schema = JsonApiResource.schema(resource)

    resource_schema =
      if document.multiple do
        %Schema{type: :array, items: resource_item_schema, title: resource.title <> "List"}
      else
        resource_item_schema
      end

    %Schema{
      type: :object,
      properties: %{
        data: resource_schema
      },
      required: [:data],
      title: document.title <> "Document"
    }
  end

  def schema(document_attrs) when is_list(document_attrs) or is_map(document_attrs) do
    __MODULE__
    |> struct!(document_attrs)
    |> schema()
  end
end
