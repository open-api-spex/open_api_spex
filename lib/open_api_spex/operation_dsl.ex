defmodule OpenApiSpex.OperationDsl do
  defmacro operation(action, spec1) do
    operation_def(action, spec1)
  end

  def operation_def(action, spec1) do
    quote do
      if !Module.get_attribute(__MODULE__, :operation_defined) do
        Module.register_attribute(__MODULE__, :spec_attributes, accumulate: true)

        @operation_defined true

        def spec_attributes do
          @spec_attributes
        end
      end

      Module.put_attribute(__MODULE__, :spec_attributes, {unquote(action), unquote(spec1)})
    end
  end
end
