defmodule OpenApiSpex.OperationDsl do
  alias OpenApiSpex.OperationBuilder

  @doc """
  Defines an Operation spec in a controller.
  """
  defmacro operation(action, spec) do
    operation_def(action, spec)
  end

  @doc """
  Defines a list of tags that all operations in a controller will share.
  """
  defmacro tags(tags) do
    tags_def(tags)
  end

  @doc false
  defmacro before_compile(_env) do
    quote do
      def open_api_operation(action) do
        module_name = __MODULE__ |> to_string() |> String.replace_leading("Elixir.", "")
        IO.warn("No operation spec defined for controller action #{module_name}.#{action}")
      end

      def controller_tags do
        Module.get_attribute(__MODULE__, :controller_tags) || []
      end
    end
  end

  @doc false
  def operation_def(action, spec) do
    quote do
      if !Module.get_attribute(__MODULE__, :operation_defined) do
        Module.register_attribute(__MODULE__, :spec_attributes, accumulate: true)

        @before_compile {OpenApiSpex.OperationDsl, :before_compile}

        @operation_defined true
      end

      @spec_attributes {unquote(action), operation_spec(__MODULE__, unquote(spec))}

      def open_api_operation(unquote(action)) do
        @spec_attributes[unquote(action)]
      end
    end
  end

  @doc false
  def tags_def(tags) do
    quote do
      @controller_tags unquote(tags)
    end
  end

  @doc false
  def operation_spec(module, spec) do
    spec = Map.new(spec)
    tags = spec[:tags] || Module.get_attribute(module, :controller_tags)

    initial_attrs = [
      tags: tags,
      responses: [],
      parameters: OperationBuilder.build_parameters(spec)
    ]

    spec = Map.delete(spec, :parameters)

    OpenApiSpex.Operation
    |> struct!(initial_attrs)
    |> struct!(spec)
  end
end
