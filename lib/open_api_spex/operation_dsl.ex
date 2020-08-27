defmodule OpenApiSpex.OperationDsl do
  @moduledoc """
  Macros for defining operation specs and operation tags in a Phoenix controller.

  If you use Elixir Formatter, be sure to add `:open_api_spex` to the `:import_deps`
  list in the `.formatter.exs` file of your project.
  """
  alias OpenApiSpex.{Operation, OperationBuilder}

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

      @spec_attributes {unquote(action),
                        operation_spec(__MODULE__, unquote(action), unquote(spec))}

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
  def operation_spec(module, action, spec) do
    spec = Map.new(spec)
    controller_tags = Module.get_attribute(module, :controller_tags) || []

    %Operation{
      description: Map.get(spec, :description),
      operationId: OperationBuilder.build_operation_id(spec, module, action),
      parameters: OperationBuilder.build_parameters(spec),
      requestBody: OperationBuilder.build_request_body(spec),
      responses: OperationBuilder.build_responses(spec),
      security: OperationBuilder.build_security(spec),
      summary: Map.get(spec, :summary),
      tags: OperationBuilder.build_tags(spec, %{tags: controller_tags})
    }
  end
end
