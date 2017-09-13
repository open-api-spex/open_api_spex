defmodule OpenApiSpex.PathsTest do
  use ExUnit.Case
  alias OpenApiSpex.{Paths, PathItem}
  alias OpenApiSpexTest.Router

  describe "Paths" do
    test "from_router" do
      paths = Paths.from_router(Router)
      assert %{
        "/api/users" => %PathItem{},
      } = paths
    end
  end
end