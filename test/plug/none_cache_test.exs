defmodule OpenApiSpex.Plug.NoneCacheTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.Plug.NoneCache
  alias OpenApiSpexTest.ApiSpec

  setup do
    [spec: ApiSpec.spec()]
  end

  describe "get/1" do
    test "returns nil", %{spec: spec} do
      assert is_nil(NoneCache.get(spec))
    end
  end

  describe "put/2" do
    test "returns :ok", %{spec: spec} do
      assert :ok = NoneCache.put(spec, %{})
    end
  end

  describe "erase/1" do
    test "returns :ok", %{spec: spec} do
      assert :ok = NoneCache.erase(spec)
    end
  end
end
