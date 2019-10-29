defmodule OpenApiSpex.PathItem do
  @moduledoc """
  Defines the `OpenApiSpex.PathItem.t` type.
  """

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

  @typedoc """
  [Path Item Object](https://swagger.io/specification/#pathItemObject)

  Describes the operations available on a single path.
  A Path Item MAY be empty, due to ACL constraints.
  The path itself is still exposed to the documentation viewer
  but they will not know which operations and parameters are available.
  """
  @type t :: %__MODULE__{
          "$ref": String.t() | nil,
          summary: String.t() | nil,
          description: String.t() | nil,
          get: Operation.t() | nil,
          put: Operation.t() | nil,
          post: Operation.t() | nil,
          delete: Operation.t() | nil,
          options: Operation.t() | nil,
          head: Operation.t() | nil,
          patch: Operation.t() | nil,
          trace: Operation.t() | nil,
          servers: [Server.t()] | nil,
          parameters: [Parameter.t() | Reference.t()] | nil
        }

  @typedoc """
  Represents a route from in a Plug/Phoenix application.
  Eg from the generated `__routes__` function in a Phoenix.Router module.
  """
  @type route ::
          %{verb: atom, plug: atom, opts: any}
          | %{verb: atom, plug: atom, plug_opts: any}

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
    attrs =
      routes
      |> Enum.map(fn route ->
        case Operation.from_route(route) do
          nil -> nil
          op -> {route.verb, op}
        end
      end)
      |> Enum.filter(& &1)

    struct(PathItem, attrs)
  end
end
