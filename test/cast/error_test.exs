defmodule OpenApiSpex.Cast.ErrorTest do
  use ExUnit.Case
  alias OpenApiSpex.Cast.Error

  describe "path_to_string/1" do
    test "with empty path" do
      error = %Error{path: []}
      assert Error.path_to_string(error) == "/"
    end
  end

  describe "message" do
    test "it returns the correct error message for :min_items errors" do
      assert "Array length 0 is smaller than minItems: 1" ==
               Error.message(%{reason: :min_items, length: 1, value: []})

      assert "Array length 1 is smaller than minItems: 2" ==
               Error.message(%{reason: :min_items, length: 2, value: ["one"]})
    end

    test "it returns the correct error message for :max_items errors" do
      assert "Array length 2 is larger than maxItems: 1" ==
               Error.message(%{reason: :max_items, length: 1, value: ["one", "two"]})
    end
  end
end
