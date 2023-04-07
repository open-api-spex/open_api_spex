defmodule OpenApiSpexTest.ApiSpec do
  alias OpenApiSpex.{
    Components,
    Contact,
    Info,
    License,
    OpenApi,
    Parameter,
    Paths,
    Schema,
    Server
  }

  alias OpenApiSpexTest.{Router, Schemas}
  @behaviour OpenApi

  @info %Info{
    title: "A",
    version: "3.0",
    contact: %Contact{
      name: "joe",
      email: "Joe@gmail.com",
      url: "https://help.joe.com"
    },
    license: %License{
      name: "MIT",
      url: "http://mit.edu/license"
    }
  }

  def info, do: @info

  def empty_spec do
    %OpenApi{
      paths: %{},
      info: @info,
      components: %Components{
        schemas: %{}
      }
    }
  end

  @impl OpenApi
  def spec() do
    %OpenApi{
      servers: [
        %Server{url: "http://example.com"}
      ],
      info: @info,
      components: %Components{
        schemas:
          for schemaMod <- [
                Schemas.Pet,
                Schemas.PetType,
                Schemas.Cat,
                Schemas.Dog,
                Schemas.CatOrDog,
                Schemas.Size,
                Schemas.Array,
                Schemas.Primitive
              ],
              into: %{} do
            schema = schemaMod.schema()
            {schema.title, schema}
          end,
        parameters: %{
          "id" => %Parameter{
            in: :path,
            name: :id,
            description: "ID",
            schema: %Schema{type: :integer, minimum: 1},
            required: true,
            example: 12
          }
        }
      },
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
