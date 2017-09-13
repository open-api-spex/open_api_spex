defmodule OpenApiSpexTest do
  use ExUnit.Case
  alias OpenApiSpexTest.ApiSpec

  describe "OpenApi" do
    test "compete" do
      spec = ApiSpec.spec()
      assert spec
    end
  end
end