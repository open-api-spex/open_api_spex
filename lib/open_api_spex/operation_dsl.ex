defmodule OpenApiSpex.OperationDsl do
  defmacro operation(action, spec) do
    operation_def(action, spec)
  end

  defmacro before_compile(_env) do
    quote do
      def spec_attributes, do: @spec_attributes
    end
  end

  def operation_def(action, spec) do
    quote do
      if !Module.get_attribute(__MODULE__, :operation_defined) do
        Module.register_attribute(__MODULE__, :spec_attributes, accumulate: true)

        @before_compile {OpenApiSpex.OperationDsl, :before_compile}

        @operation_defined true
      end

      @spec_attributes {unquote(action), operation_spec(unquote(spec))}
    end
  end

  def operation_spec(spec) do
    struct!(OpenApiSpex.Operation, spec)
  end
end
