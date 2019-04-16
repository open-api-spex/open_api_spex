defmodule OpenApiSpexTest.UserControllerAnnotated do
  use OpenApiSpex.Controller

  @moduledoc tags: ["Foo"]

  @doc """
  Endpoint summary

  More docs
  """
  @doc parameters: [
    id: [in: :path, type: :string, required: true]
  ]
  @doc responses: [
    ok: {"Foo document", "application/json", FooSchema}
  ]
  def show, do: :ok
end

