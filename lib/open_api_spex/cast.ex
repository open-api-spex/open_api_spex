defmodule OpenApiSpex.Cast do
  @moduledoc false
  alias OpenApiSpex.{Discriminator, Reference, Schema}

  def cast(%Schema{nullable: true}, nil, _schemas), do: {:ok, nil}
  def cast(%Schema{type: :boolean}, value, _schemas) when is_boolean(value), do: {:ok, value}

  def cast(%Schema{type: :boolean}, value, _schemas) when is_binary(value) do
    case value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> {:error, "Invalid boolean: #{inspect(value)}"}
    end
  end

  def cast(%Schema{type: :boolean}, value, _schemas) do
    {:error, "Invalid boolean: #{inspect(value)}"}
  end

  def cast(%Schema{type: :integer}, value, _schemas) when is_integer(value), do: {:ok, value}

  def cast(%Schema{type: :integer}, value, _schemas) when is_binary(value) do
    case Integer.parse(value) do
      {i, ""} -> {:ok, i}
      _ -> {:error, "Invalid integer: #{inspect(value)}"}
    end
  end

  def cast(%Schema{type: :integer}, value, _schemas) do
    {:error, "Invalid integer: #{inspect(value)}"}
  end

  def cast(%Schema{type: :number, format: fmt}, value, _schema)
      when is_integer(value) and fmt in [:float, :double] do
    {:ok, value * 1.0}
  end

  def cast(%Schema{type: :number}, value, _schemas) when is_number(value), do: {:ok, value}

  def cast(%Schema{type: :number}, value, _schemas) when is_binary(value) do
    case Float.parse(value) do
      {x, ""} -> {:ok, x}
      _ -> {:error, "Invalid number: #{inspect(value)}"}
    end
  end

  def cast(%Schema{type: :number}, value, _schemas) do
    {:error, "Invalid number: #{inspect(value)}"}
  end

  def cast(%Schema{type: :string, format: :"date-time"}, value, _schemas) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime = %DateTime{}, _offset} -> {:ok, datetime}
      error = {:error, _reason} -> error
    end
  end

  def cast(%Schema{type: :string, format: :date}, value, _schemas) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date = %Date{}} -> {:ok, date}
      error = {:error, _reason} -> error
    end
  end

  def cast(%Schema{type: :string}, value, _schemas) when is_binary(value), do: {:ok, value}

  def cast(%Schema{type: :string}, value, _schemas) do
    {:error, "Invalid string: #{inspect(value)}"}
  end

  def cast(%Schema{type: :array, items: nil}, value, _schemas) when is_list(value),
    do: {:ok, value}

  def cast(%Schema{type: :array}, [], _schemas), do: {:ok, []}

  def cast(schema = %Schema{type: :array, items: items_schema}, [x | rest], schemas) do
    with {:ok, x_cast} <- cast(items_schema, x, schemas),
         {:ok, rest_cast} <- cast(schema, rest, schemas) do
      {:ok, [x_cast | rest_cast]}
    end
  end

  def cast(%Schema{type: :array}, value, _schemas) when not is_list(value) do
    {:error, "Invalid array: #{inspect(value)}"}
  end

  def cast(%Schema{type: :object}, value, _schemas) when not is_map(value) do
    {:error, "Invalid object: #{inspect(value)}"}
  end

  def cast(
        schema = %Schema{type: :object, discriminator: discriminator = %{}},
        value = %{},
        schemas
      ) do
    discriminator_property = String.to_existing_atom(discriminator.propertyName)

    already_cast? =
      if Map.has_key?(value, discriminator_property) do
        {:error, :already_cast}
      else
        :ok
      end

    with :ok <- already_cast?,
         {:ok, partial_cast} <-
           cast(%Schema{type: :object, properties: schema.properties}, value, schemas),
         {:ok, derived_schema} <- Discriminator.resolve(discriminator, value, schemas),
         {:ok, result} <- cast(derived_schema, partial_cast, schemas) do
      {:ok, make_struct(result, schema)}
    else
      {:error, :already_cast} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  def cast(schema = %Schema{type: :object, allOf: [first | rest]}, value = %{}, schemas) do
    with {:ok, cast_first} <- cast(first, value, schemas),
         {:ok, result} <- cast(%{schema | allOf: rest}, cast_first, schemas) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def cast(schema = %Schema{type: :object, allOf: []}, value = %{}, schemas) do
    cast(%{schema | allOf: nil}, value, schemas)
  end

  def cast(schema = %Schema{oneOf: [first | rest]}, value, schemas) do
    case cast(first, value, schemas) do
      {:ok, result} ->
        cast(%{schema | oneOf: nil}, result, schemas)

      {:error, _reason} ->
        cast(%{schema | oneOf: rest}, value, schemas)
    end
  end

  def cast(%Schema{oneOf: []}, _value, _schemas) do
    {:error, "Failed to cast to any schema in oneOf"}
  end

  def cast(schema = %Schema{anyOf: [first | rest]}, value, schemas) do
    case cast(first, value, schemas) do
      {:ok, result} ->
        cast(%{schema | anyOf: nil}, result, schemas)

      {:error, _reason} ->
        cast(%{schema | anyOf: rest}, value, schemas)
    end
  end

  def cast(%Schema{anyOf: []}, _value, _schemas) do
    {:error, "Failed to cast to any schema in anyOf"}
  end

  def cast(schema = %Schema{type: :object}, value, schemas) when is_map(value) do
    schema = %{schema | properties: schema.properties || %{}}

    {regular_properties, others} =
      value
      |> no_struct()
      |> Enum.split_with(fn {k, _v} -> is_binary(k) end)

    with {:ok, props} <- cast_properties(schema, regular_properties, schemas) do
      result = Map.new(others ++ props) |> make_struct(schema)
      {:ok, result}
    end
  end

  def cast(ref = %Reference{}, val, schemas),
    do: cast(Reference.resolve_schema(ref, schemas), val, schemas)

  def cast(_additionalProperties = false, val, _schemas) do
    {:error, "Unexpected field with value #{inspect(val)}"}
  end

  def cast(_additionalProperties, val, _schemas), do: {:ok, val}

  defp make_struct(val = %_{}, _), do: val
  defp make_struct(val, %{"x-struct": nil}), do: val

  defp make_struct(val, %{"x-struct": mod}) do
    Enum.reduce(val, struct(mod), fn {k, v}, acc ->
      Map.put(acc, k, v)
    end)
  end

  defp no_struct(val), do: Map.delete(val, :__struct__)

  @spec cast_properties(Schema.t(), list, %{String.t() => Schema.t()}) ::
          {:ok, list} | {:error, String.t()}
  defp cast_properties(%Schema{}, [], _schemas), do: {:ok, []}

  defp cast_properties(object_schema = %Schema{}, [{key, value} | rest], schemas) do
    {name, schema} =
      Enum.find(
        object_schema.properties,
        {key, object_schema.additionalProperties},
        fn {name, _schema} -> to_string(name) == to_string(key) end
      )

    with {:ok, new_value} <- cast(schema, value, schemas),
         {:ok, cast_tail} <- cast_properties(object_schema, rest, schemas) do
      {:ok, [{name, new_value} | cast_tail]}
    end
  end
end
