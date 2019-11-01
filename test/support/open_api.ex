defmodule OpenApiSpexTest.OpenApi do
  alias OpenApiSpex.{Components, Info, OpenApi}

  @doc """
  Build an %OpenApi{} struct from a list of schema modules.
  """
  @spec build(schemas :: [module]) :: OpenApi.t()
  def build(schemas) do
    schemas_map =
      for module <- schemas, into: %{} do
        {module.schema().title, module.schema()}
      end

    info = %Info{
      title: "Test schema",
      version: "1.0.0"
    }

    %OpenApi{info: info, paths: %{}, components: %Components{schemas: schemas_map}}
    |> OpenApiSpex.resolve_schema_modules()
  end
end
