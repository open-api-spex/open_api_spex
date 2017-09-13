defmodule OpenApiSpex.Paths do
  alias OpenApiSpex.PathItem

  @type t :: %{String.t => PathItem.t}

  @doc """
  Create a Paths map from the routes in the given router module.
  """
  @spec from_router(module) :: t
  def from_router(router) do
    router.__routes__()
    |> Enum.group_by(fn route -> route.path end)
    |> Enum.map(fn {k, v} -> {open_api_path(k), PathItem.from_routes(v)} end)
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> Map.new()
  end

  @spec open_api_path(String.t) :: String.t
  defp open_api_path(path) do
    path
    |> String.split("/")
    |> Enum.map(fn ":"<>segment -> "{#{segment}}"; segment -> segment end)
    |> Enum.join("/")
  end
end