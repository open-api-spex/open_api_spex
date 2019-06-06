defmodule OpenApiSpex.EncodeTest do
  use ExUnit.Case

  alias OpenApiSpex.{
    Info,
    OpenApi
  }

  test "Vendor extensions x-logo properly encoded" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0",
        extensions: %{
          "x-logo" => %{
            "url" => "https://example.com/logo.png",
            "backgroundColor" => "#FFFFFF",
            "altText" => "Example logo"
          }
        }
      },
      paths: %{}
    }

    decoded =
      OpenApiSpex.resolve_schema_modules(spec)
      |> Jason.encode!()
      |> Jason.decode!()

    assert decoded["info"]["x-logo"]["url"] == "https://example.com/logo.png"
    assert decoded["info"]["x-logo"]["backgroundColor"] == "#FFFFFF"
    assert decoded["info"]["x-logo"]["altText"] == "Example logo"

    assert is_nil(decoded["info"]["extensions"])
  end

  test "Vendor extensions x-tagGroups properly encoded" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      extensions: %{
        "x-tagGroups" => [
          %{
            "name" => "Methods",
            "tags" => [
              "Search",
              "Fetch",
              "Delete"
            ]
          }
        ]
      },
      paths: %{}
    }

    decoded =
      OpenApiSpex.resolve_schema_modules(spec)
      |> Jason.encode!()
      |> Jason.decode!()

    assert hd(decoded["x-tagGroups"])["name"] == "Methods"
    assert hd(decoded["x-tagGroups"])["tags"] == ["Search", "Fetch", "Delete"]

    assert is_nil(decoded["extensions"])
  end
end
