defmodule OpenApiSpex.PathItem do
  alias OpenApiSpex.{Operation, Server, Parameter, PathItem, Reference}
  defstruct [
    :"$ref",
    :summary,
    :description,
    :get,
    :put,
    :post,
    :delete,
    :options,
    :head,
    :patch,
    :trace,
    :servers,
    :parameters
  ]
  @type t :: %__MODULE__{
    "$ref": String.t,
    summary: String.t,
    description: String.t,
    get: Operation.t,
    put: Operation.t,
    post: Operation.t,
    delete: Operation.t,
    options: Operation.t,
    head: Operation.t,
    patch: Operation.t,
    trace: Operation.t,
    servers: [Server.t],
    parameters: [Parameter.t | Reference.t]
  }

  @type route :: %{verb: atom, plug: atom, opts: any}

  @doc """
  Builds a PathItem struct from a list of routes that share a path.
  """
  @spec from_routes([route]) :: nil | t
  def from_routes(routes) do
    Enum.each(routes, fn route ->
      Code.ensure_loaded(route.plug)
    end)

    routes
    |> Enum.filter(&function_exported?(&1.plug, :open_api_operation, 1))
    |> from_valid_routes()
  end

  @spec from_valid_routes([route]) :: nil | t
  defp from_valid_routes([]), do: nil
  defp from_valid_routes(routes) do
    struct(PathItem, Enum.map(routes, &{&1.verb, Operation.from_route(&1)}))
  end
end