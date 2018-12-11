defmodule OpenApiSpex.Cast.ErrorTest do
  use ExUnit.Case
  alias OpenApiSpex.Cast.Error

  describe "path_to_string/1" do
    test "with empty path" do
      error = %Error{path: []}
      Error.path_to_string(error)
    end
  end
end
