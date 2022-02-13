defmodule OpenApiSpex.SchemaConsistency do
  @moduledoc """
  Rules of API Schema consistency.
  If these rules are not followed, tricky run-time bugs may appear.
  Related issues: #144
  """

  alias OpenApiSpex.Schema

  @doc "Returns a list of compile-time warnings"
  @spec warnings(Schema.t()) :: list(binary())
  def warnings(schema) do
    [
      &validate_type_key/1
    ]
    |> Enum.reduce([], fn validator, acc ->
      case validator.(schema) do
        :ok -> acc
        {:error, message} -> [message | acc]
      end
    end)
  end

  ## Specific validations

  # if :type is missing or nil, :properties are ignored and the nested schemas are not validated

  defp validate_type_key(%Schema{properties: %{}, type: type}) do
    case type do
      :object -> :ok
      nil -> {:error, ":properties provided, but :type is missing or nil (expected :object)"}
      type -> {:error, ":properties provided, but :type is #{inspect(type)} (expected :object)"}
    end
  end

  defp validate_type_key(_), do: :ok
end
