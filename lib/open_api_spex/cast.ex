defmodule OpenApiSpex.Cast do
  @moduledoc false
  alias OpenApiSpex.{Error, Discriminator, Reference, Schema, Validation}

  def cast(%Validation{schema: %{nullable: true}, value: nil} = validation) do
    {:ok, validation}
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation)
      when is_boolean(value) do
    {:ok, validation}
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation)
      when is_binary(value) do
    case value do
      "true" -> {:ok, %{validation | value: true}}
      "false" -> {:ok, %{validation | value: false}}
      _ -> {:error, %{validation | error: Error.new(:unexpected_type, :boolean, value)}}
    end
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation) do
    {:error, %{validation | error: Error.new(:unexpected_type, :boolean, value)}}
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation)
      when is_integer(value) do
    {:ok, %{validation | value: value}}
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation)
      when is_binary(value) do
    case Integer.parse(value) do
      {int_value, ""} -> {:ok, %{validation | value: int_value}}
      _ -> {:error, %{validation | error: Error.new(:unexpected_type, :integer, value)}}
    end
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation) do
    {:error, %{validation | error: Error.new(:unexpected_type, :integer, value)}}
  end

  def cast(%Validation{schema: %{type: :number, format: fmt}, value: value} = validation)
      when is_integer(value) and fmt in [:float, :double] do
    {:ok, %{validation | value: value * 1.0}}
  end

  def cast(%Validation{schema: %{type: :number}, value: value} = validation)
      when is_number(value),
      do: {:ok, validation}

  def cast(%Validation{schema: %{type: :number}, value: value} = validation)
      when is_binary(value) do
    case Float.parse(value) do
      {x, ""} -> {:ok, %{validation | value: x}}
      _ -> {:error, %{validation | error: Error.new(:unexpected_type, :number, value)}}
    end
  end

  def cast(%Validation{schema: %{type: :number}, value: value} = validation) do
    {:error, %{validation | error: Error.new(:unexpected_type, :number, value)}}
  end

  def cast(%Validation{schema: %{type: :string, format: :"date-time"}, value: value} = validation)
      when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime = %DateTime{}, _offset} -> {:ok, %{validation | value: datetime}}
      {:error, reason} -> {:error, %{validation | error: reason}}
    end
  end

  def cast(%Validation{schema: %{type: :string, format: :date}, value: value} = validation)
      when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date = %Date{}} -> {:ok, %{validation | value: date}}
      {:error, _} -> {:error, %{validation | error: Error.new(:invalid_format, :date, value)}}
    end
  end

  def cast(%Validation{schema: %{type: :string}, value: value} = validation)
      when is_binary(value) do
    {:ok, %{validation | value: value}}
  end

  def cast(%Validation{schema: %{type: :string}, value: value} = validation) do
    {:error, %{validation | error: Error.new(:unexpected_type, :string, value)}}
  end

  def cast(%Validation{schema: %{type: :array, items: nil}, value: value} = validation)
      when is_list(value) do
    {:ok, %{validation | value: value}}
  end

  def cast(%Validation{schema: %{type: :array}, value: []} = validation),
    do: {:ok, %{validation | value: []}}

  def cast(
        %Validation{schema: %{type: :array, items: items_schema}, value: [item | rest]} =
          validation
      ) do
    with {:ok, %{value: item_cast}} <- cast(%{validation | schema: items_schema, value: item}),
         {:ok, %{value: rest_cast}} <- cast(%{validation | value: rest}) do
      {:ok, %{validation | value: [item_cast | rest_cast]}}
    end
  end

  def cast(%Validation{schema: %{type: :array}, value: value} = validation)
      when not is_list(value) do
    {:error, %{validation | error: Error.new(:unexpected_type, :array, value)}}
  end

  def cast(%Validation{schema: %{type: :object}, value: value} = validation)
      when not is_map(value) do
    {:error, %{validation | error: Error.new(:unexpected_type, :object, value)}}
  end

  def cast(
        %Validation{
          schema: %{type: :object, discriminator: %{} = discriminator} = schema,
          value: %{} = value
        } = validator
      ) do
    discriminator_property = String.to_existing_atom(discriminator.propertyName)

    already_cast? =
      if Map.has_key?(value, discriminator_property) do
        {:error, :already_cast}
      else
        :ok
      end

    with :ok <- already_cast?,
         {:ok, %{value: partial_cast}} <-
           cast(%{
             validator
             | schema: %Schema{type: :object, properties: schema.properties},
               value: value
           }),
         {:ok, validator_1} <- discriminate(validator, discriminator),
         {:ok, %{value: value}} <- cast(%{validator_1 | value: partial_cast}) do
      {:ok, %{validator | value: make_struct(value, schema)}}
    else
      {:error, :already_cast} -> {:ok, %{validator | value: value}}
      {:error, validator} -> {:error, validator}
    end
  end

  def cast(%Validation{schema: %{type: :object, allOf: [first | rest]}, value: %{}} = validation) do
    schema = validation.schema

    with {:ok, validation} <- cast(%{validation | schema: first}),
         {:ok, validation} <- cast(%{validation | schema: %{schema | allOf: rest}}) do
      {:ok, validation}
    end
  end

  def cast(
        %Validation{schema: schema = %Schema{type: :object, allOf: []}, value: value = %{}} =
          validation
      ) do
    cast(%{validation | schema: %{schema | allOf: nil}, value: value})
  end

  def cast(
        %Validation{schema: %{oneOf: [first | rest]} = schema, value: value, schemas: schemas} =
          validation
      ) do
    case cast(%Validation{schema: first, value: value, schemas: schemas}) do
      {:ok, %{value: value}} ->
        cast(%Validation{schema: %{schema | oneOf: nil}, value: value, schemas: schemas})

      {:error, _} ->
        cast(%{validation | schema: %{schema | oneOf: rest}})
    end
  end

  def cast(%Validation{schema: %{oneOf: []}, value: value} = validation) do
    {:error, %{validation | error: Error.new(:polymorphic_failed, value, :oneOf)}}
  end

  def cast(%Validation{schema: schema = %Schema{anyOf: [first | rest]}} = validation) do
    case cast(%{validation | schema: first}) do
      {:ok, %{value: result}} ->
        cast(%{validation | schema: %{schema | anyOf: nil}, value: result})

      {:error, _} ->
        cast(%{validation | schema: %{schema | anyOf: rest}})
    end
  end

  def cast(%Validation{schema: %{anyOf: []}, value: value} = validation) do
    {:error, %{validation | error: Error.new(:polymorphic_failed, value, :anyOf)}}
  end

  def cast(
        %Validation{schema: schema = %Schema{type: :object}, value: value, schemas: schemas} =
          validation
      )
      when is_map(value) do
    schema = %{schema | properties: schema.properties || %{}}

    {regular_properties, others} =
      value
      |> no_struct()
      |> Enum.split_with(fn {k, _v} -> is_binary(k) end)

    with {:ok, props} <- cast_properties(schema, regular_properties, schemas) do
      result = Map.new(others ++ props) |> make_struct(schema)
      {:ok, %{validation | value: result}}
    else
      {:error, error} -> {:error, %{validation | error: error}}
    end
  end

  def cast(%Validation{schema: ref = %Reference{}, schemas: schemas} = validation) do
    cast(%{validation | schema: Reference.resolve_schema(ref, schemas)})
  end

  def cast(%Validation{schema: _additionalProperties = false, value: value} = validation) do
    {:error, %{validation | error: Error.new(:unexpected_field, value)}}
  end

  def cast(%Validation{} = validation), do: {:ok, validation}

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

    with {:ok, %{value: new_value}} <-
           cast(%Validation{schema: schema, value: value, schemas: schemas}),
         {:ok, cast_tail} <- cast_properties(object_schema, rest, schemas) do
      {:ok, [{name, new_value} | cast_tail]}
    end
  end

  defp discriminate(%{value: value, schemas: schemas} = validator, discriminator) do
    case Discriminator.resolve(discriminator, value, schemas) do
      {:ok, derived_schema} -> {:ok, %{validator | schema: derived_schema}}
      {:error, reason} -> {:error, %{validator | error: reason}}
    end
  end
end
