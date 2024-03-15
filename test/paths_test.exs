defmodule OpenApiSpex.PathsTest do
  use ExUnit.Case
  alias OpenApiSpex.{Paths, PathItem}
  alias OpenApiSpexTest.Router

  describe "Paths" do
    test "from_router" do
      paths = Paths.from_router(Router)

      assert %{
               "/api/users" => %PathItem{},
               "/api/pets/{id}" => pets_path_item
             } = paths

      refute Map.has_key?(paths, "/api/noapi")
      refute Map.has_key?(paths, "/api/noapi_with_struct")

      operation_ids = [pets_path_item.put.operationId, pets_path_item.patch.operationId]

      assert "OpenApiSpexTest.PetController.update" in operation_ids
      assert "OpenApiSpexTest.PetController.update (2)" in operation_ids
    end
  end
end
