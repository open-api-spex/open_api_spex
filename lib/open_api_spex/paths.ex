defmodule OpenApiSpex.Paths do
  @moduledoc """
  Defines the `OpenApiSpex.Paths.t` type.
  """
  alias OpenApiSpex.{Operation, PathItem}

  @typedoc """
  [Paths Object](https://swagger.io/specification/#pathsObject)

  Holds the relative paths to the individual endpoints and their operations.
  The path is appended to the URL from the Server Object in order to construct the full URL.
  The Paths MAY be empty, due to ACL constraints.
  """
  @type path :: String.t()
  @type t :: %{path => PathItem.t()}

  @typep operation_id :: String.t()
  @typep verb :: atom

  @doc """
  Create a Paths map from the routes in the given router module.
  """
  @spec from_router(module) :: t
  def from_router(router), do: from_routes(router.__routes__())

  @doc """
  Create a Paths map from a list of routes.
  """
  @spec from_routes([%{path: String.t(), verb: atom()}]) :: t
  def from_routes(routes) do
    paths =
      routes
      |> Enum.group_by(fn route -> route.path end)
      |> Enum.map(fn {k, v} -> {open_api_path(k), PathItem.from_routes(v)} end)
      |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
      |> Map.new()

    paths
    |> find_duplicate_operations()
    |> make_operation_ids_unique()
    |> Enum.reduce(paths, fn {path, verb, operation}, paths ->
      Map.update!(paths, path, fn path_item ->
        %{path_item | verb => operation}
      end)
    end)
  end

  @spec open_api_path(String.t()) :: String.t()
  defp open_api_path(path) do
    path
    |> String.split("/")
    |> Enum.map_join("/", fn
      ":" <> segment -> "{#{segment}}"
      segment -> segment
    end)
  end

  @spec find_duplicate_operations(paths :: t) :: [{operation_id, [{path, verb, Operation.t()}]}]
  defp find_duplicate_operations(paths) do
    all_operations =
      for {path, path_item} <- paths,
          {verb, operation = %Operation{}} <- Map.from_struct(path_item),
          do: {path, verb, operation}

    all_operations
    |> Enum.group_by(fn {_path, _verb, operation} -> operation.operationId end)
    |> Enum.filter(fn
      {_operation_id, [_item]} -> false
      _ -> true
    end)
  end

  @spec make_operation_ids_unique([{operation_id, [{path, verb, Operation.t()}]}]) ::
          [{path, verb, Operation.t()}]
  defp make_operation_ids_unique(duplicate_operations) do
    duplicate_operations
    |> Enum.flat_map(fn {operation_id, [_first | rest]} ->
      rest
      |> Enum.with_index(2)
      |> Enum.map(fn {{path, verb, operation}, occurrence} ->
        {path, verb, %{operation | operationId: "#{operation_id} (#{occurrence})"}}
      end)
    end)
  end
end
