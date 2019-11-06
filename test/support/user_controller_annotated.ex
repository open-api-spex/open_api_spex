defmodule OpenApiSpexTest.UserControllerAnnotated do
  use OpenApiSpex.Controller
  alias OpenApiSpexTest.Schemas.User

  @moduledoc tags: ["User"]

  @doc """
  Update a user

  Full description for this endpoint...
  """
  @doc parameters: [
         id: [in: :path, type: :string, required: true]
       ]
  @doc request_body: {"Request body to update a User", "application/json", User, required: true}
  @doc responses: [
         ok: {"User response", "application/json", User}
       ]
  def update(_conn, _params), do: :ok
end
