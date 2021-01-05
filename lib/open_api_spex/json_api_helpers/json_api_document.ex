defmodule OpenApiSpex.JsonApiHelpers.JsonApiDocument do
  alias OpenApiSpex.Schema
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource

  defstruct resource: nil,
            multiple: false,
            paginated: false,
            title: nil,
            "x-struct": nil

  def schema(%__MODULE__{} = document) do
    if not is_binary(document.title) do
      raise "%JsonApiDocument{} :title is required and must be a string"
    end

    resource = document.resource
    resource_item_schema = JsonApiResource.schema(resource)

    resource_title =
      case resource_item_schema do
        %Schema{} = schema -> schema.title
        module when is_atom(module) and not is_nil(module) -> module.schema().title
      end

    resource_schema =
      if document.multiple || document.paginated do
        %Schema{
          type: :array,
          items: resource_item_schema,
          title: resource_title <> "List"
        }
      else
        resource_item_schema
      end

    properties = %{
      data: resource_schema
    }

    properties =
      if document.paginated do
        Map.put(properties, :links, pagination_spec())
      else
        properties
      end

    %Schema{
      type: :object,
      properties: properties,
      required: [:data],
      title: document.title,
      "x-struct": document."x-struct"
    }
  end

  def schema(document_attrs) when is_list(document_attrs) or is_map(document_attrs) do
    __MODULE__
    |> struct!(document_attrs)
    |> schema()
  end

  def pagination_spec() do
    # https://jsonapi.org/format/#fetching-pagination
    # TODO: Links can be omitted or nullable, nullable should be delcared!
    %Schema{
      type: :object,
      properties: %{
        prev: %Schema{
          type: :string,
          description: "Link to the previous page of results",
          nullable: true,
          readOnly: true
        },
        next: %Schema{
          type: :string,
          description: "Link to the next page of results",
          nullable: true,
          readOnly: true
        },
        last: %Schema{
          type: :string,
          description: "Link to the last page of results",
          nullable: true,
          readOnly: true
        },
        first: %Schema{
          type: :string,
          description: "Link to the first page of results",
          nullable: true,
          readOnly: true
        }
      }
    }
  end
end
