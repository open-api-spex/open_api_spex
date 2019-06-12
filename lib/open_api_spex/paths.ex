defmodule OpenApiSpex.Paths do
  @moduledoc """
  Defines the `OpenApiSpex.Paths.t` type.
  """
  alias OpenApiSpex.PathItem

  @typedoc """
  [Paths Object](https://swagger.io/specification/#pathsObject)

  Holds the relative paths to the individual endpoints and their operations.
  The path is appended to the URL from the Server Object in order to construct the full URL.
  The Paths MAY be empty, due to ACL constraints.
  """
  @type t :: %{String.t() => PathItem.t()}

  @doc """
  Create a Paths map from the routes in the given router module.
  """
  @spec from_router(module) :: {:ok, t} | {:error, String.t()}
  def from_router(router) do
    router.__routes__()
    |> Enum.group_by(fn route -> open_api_path(route.path) end)
    |> Enum.map(fn {path, routes} -> {path, PathItem.from_routes(routes)} end)
    |> Enum.reduce_while(%{}, fn
      {_path, {:error, reason}}, _acc -> {:halt, {:error, reason}}
      {_path, {:ok, nil}}, acc -> {:cont, acc}
      {path, {:ok, path_item}}, acc -> {:cont, Map.put(acc, path, path_item)}
    end)
    |> case do
      {:error, reason} -> raise reason
      paths -> paths
    end
  end

  @spec open_api_path(String.t()) :: String.t()
  defp open_api_path(path) do
    pattern = ~r{:([^/]+)}
    Regex.replace(pattern, path, "{\\1}")
  end
end
