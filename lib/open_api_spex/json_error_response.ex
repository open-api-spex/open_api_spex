defmodule OpenApiSpex.JsonErrorResponse do
  @moduledoc """
  Schema for the default error renderer used by `OpenApiSpex.Plug.CastAndValidate`.

  ## Examples

      @doc responses: %{
             201 => {"User", "application/json", UserResponse}
             422 => {"Unprocessable Entity"], "application/json", OpenApiSpex.JsonApiErrorResponse}
           }
  """
  require OpenApiSpex
  alias OpenApiSpex.{Operation, Schema}

  OpenApiSpex.schema(%{
    type: :object,
    properties: %{
      errors: %Schema{
        type: :array,
        items: %Schema{
          properties: %{
            title: %Schema{type: :string, example: "Invalid value"},
            source: %Schema{
              type: :object,
              properties: %{
                pointer: %Schema{type: :string, example: "/data/attributes/petName"}
              },
              required: [:pointer]
            },
            detail: %Schema{type: :string, example: "null value where string expected"}
          },
          required: [:title, :source, :detail]
        }
      }
    },
    required: [:errors]
  })

  @doc """
  Convenience function to return that wraps JsonApiErrorResponse in an Operation response.

  ## Examples

      @doc responses: %{
             201 => {"User", "application/json", UserResponse}
             422 => OpenApiSpex.JsonApiErrorResponse.response()
           }
  """
  def response do
    Operation.response(
      "Unprocessible Entity",
      "application/json",
      __MODULE__
    )
  end
end
