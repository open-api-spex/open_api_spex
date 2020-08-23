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

      assert pets_path_item.patch.operationId == "OpenApiSpexTest.PetController.update"
      assert pets_path_item.put.operationId == "OpenApiSpexTest.PetController.update (2)"
    end
  end
end
