defmodule OpenApiSpexTest.OneOfSchemas do
  alias OpenApiSpex.Schema
  require OpenApiSpex

  defmodule Cat do
    OpenApiSpex.schema(%{
      title: "Cat",
      type: :object,
      properties: %{
        meow: %Schema{type: :boolean},
        age: %Schema{type: :integer}
      }
    })
  end

  defmodule Dog do
    OpenApiSpex.schema(%{
      title: "Dog",
      type: :object,
      properties: %{
        bark: %Schema{type: :boolean},
        breed: %Schema{type: :string, enum: ["Dingo", "Husky", "Retriever", "Shepherd"]}
      }
    })
  end

  defmodule CatOrDog do
    OpenApiSpex.schema(%{
      title: "CatOrDog",
      oneOf: [Cat, Dog]
    })
  end

  def spec() do
    OpenApiSpexTest.OpenApi.build([Cat, Dog, CatOrDog])
  end
end
