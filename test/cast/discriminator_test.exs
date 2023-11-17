defmodule OpenApiSpex.CastDiscriminatorTest do
  use ExUnit.Case

  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Discriminator, Error}

  # The discriminator we'll be using across the tests. Animal type was
  # specifically chosen to help the examples be more clear since abstract
  # objects can be difficult to grok in this context.
  @discriminator "animal_type"

  defp cast(ctx) do
    Discriminator.cast(struct(Cast, ctx))
  end

  # This function is used for testing descriminators within nested
  # schemas.
  defp cast_cast(ctx) do
    Cast.cast(struct(Cast, ctx))
  end

  # Maps an arbitrary string value to a schema
  def build_discriminator_mapping(name, schema) do
    %{name => schema_ref(schema)}
  end

  def schema_ref(%{title: title}), do: "#/components/schemas/#{title}"

  def build_schema(title, properties) do
    %Schema{
      type: :object,
      title: title,
      properties: properties
    }
  end

  def build_discriminator_schema(schemas, composite_keyword, property_name, mappings \\ nil) do
    %Schema{
      type: :object,
      discriminator: %{
        propertyName: "#{property_name}",
        mapping: mappings
      }
    }
    |> Map.put(composite_keyword, schemas)
  end

  setup do
    dog_schema =
      build_schema("Dog", %{
        animal_type: %Schema{type: :string},
        breed: %Schema{type: :string},
        age: %Schema{type: :integer}
      })

    wolf_schema =
      build_schema("Wolf", %{
        animal_type: %Schema{type: :string},
        breed: %Schema{type: :string, minLength: 5},
        age: %Schema{type: :integer}
      })

    cat_schema =
      build_schema("Cat", %{
        animal_type: %Schema{type: :string},
        breed: %Schema{type: :string},
        lives: %Schema{type: :integer}
      })

    {:ok, schemas: %{dog: dog_schema, cat: cat_schema, wolf: wolf_schema}}
  end

  describe "cast/1" do
    test "basics, anyOf", %{schemas: %{dog: dog, wolf: wolf}} do
      # "animal_type" is the discriminator
      input_value = %{@discriminator => "Dog", "breed" => "Pug", "age" => 1}
      # Create the discriminator schema. Discriminators require a composite
      # key be provided (`allOf`, `anyOf`, `oneOf`).
      discriminator_schema =
        build_discriminator_schema([dog, wolf], :anyOf, String.to_atom(@discriminator), nil)

      # Note: We're expecting to getting atoms back, not strings
      expected = {:ok, %{age: 1, breed: "Pug", animal_type: "Dog"}}

      assert cast(value: input_value, schema: discriminator_schema) == expected
    end

    test "basics, anyOf, input with atom keys", %{schemas: %{dog: dog, wolf: wolf}} do
      input_value = %{String.to_atom(@discriminator) => "Dog", breed: "Pug", age: 1}
      # Create the discriminator schema. Discriminators require a composite
      # key be provided (`allOf`, `anyOf`, `oneOf`).
      discriminator_schema =
        build_discriminator_schema([dog, wolf], :anyOf, String.to_atom(@discriminator), nil)

      # Note: We're expecting to getting atoms back, not strings
      expected = {:ok, %{age: 1, breed: "Pug", animal_type: "Dog"}}

      assert cast(value: input_value, schema: discriminator_schema) == expected
    end

    test "basics, allOf", %{schemas: %{dog: dog, wolf: wolf}} do
      # Wolf has a constraint on its "breed attribute" requiring the breed to have
      # a minimum length of 5.
      input_value = %{@discriminator => "Dog", "breed" => "Corgi", "age" => 1}

      discriminator_schema =
        build_discriminator_schema([dog, wolf], :allOf, String.to_atom(@discriminator), nil)

      # Note: We're expecting to getting atoms back, not strings
      expected = {:ok, %{age: 1, breed: "Corgi", animal_type: "Dog"}}

      assert cast(value: input_value, schema: discriminator_schema) == expected
    end

    test "basics, oneOf", %{schemas: %{dog: dog, wolf: wolf}} do
      # Wolf has a constraint on its "breed attribute" requiring the breed to have
      # a minimum length of 5.
      input_value = %{@discriminator => "Dog", "breed" => "Pug", "age" => 1}

      discriminator_schema =
        build_discriminator_schema([dog, wolf], :oneOf, String.to_atom(@discriminator), nil)

      # Note: We're expecting to getting atoms back, not strings
      expected = {:ok, %{age: 1, breed: "Pug", animal_type: "Dog"}}

      assert cast(value: input_value, schema: discriminator_schema) == expected
    end

    test "with mapping", %{schemas: %{dog: dog, cat: cat}} do
      dog_schema_alias = "dag"
      # "animal_type" is the discriminator and the keys need to be strings.
      input_value = %{@discriminator => dog_schema_alias, "breed" => "Corgi", "age" => 1}
      # Map the value 'dag' to the schema "Dog"
      mapping = build_discriminator_mapping(dog_schema_alias, dog)
      # Create the discriminator schema. Discriminators require a composite
      # key be provided (`allOf`, `anyOf`, `oneOf`).
      discriminator_schema =
        build_discriminator_schema([dog, cat], :anyOf, String.to_atom(@discriminator), mapping)

      # Note: We're expecting to getting atoms back, not strings
      expected = {:ok, %{age: 1, breed: "Corgi", animal_type: "dag"}}

      assert cast(value: input_value, schema: discriminator_schema) == expected
    end

    test "without title", %{schemas: %{dog: dog, cat: cat}} do
      dog = Map.put(dog, :title, nil)
      cat = Map.put(cat, :title, nil)

      schemas = %{"Dog" => dog, "Cat" => cat}

      discriminator_schema = %OpenApiSpex.Schema{
        anyOf: [
          %OpenApiSpex.Reference{"$ref": "#/components/schemas/Dog"},
          %OpenApiSpex.Reference{"$ref": "#/components/schemas/Cat"}
        ],
        discriminator: %{
          mapping: %{"dog" => "#/components/schemas/Dog", "cat" => "#/components/schemas/Cat"},
          propertyName: "animal_type"
        },
        type: :object
      }

      input_value = %{@discriminator => "dog", "breed" => "Corgi", "age" => 1}
      expected = {:ok, %{age: 1, breed: "Corgi", animal_type: "dog"}}
      assert cast(value: input_value, schema: discriminator_schema, schemas: schemas) == expected
    end

    test "valid discriminator mapping but schema does not match", %{
      schemas: %{dog: dog, wolf: wolf, cat: cat}
    } do
      # Wolf has a constraint on its "breed attribute" requiring the breed to have
      # a minimum length of 5.
      input_value = %{@discriminator => "Wolf", "breed" => "pug", "age" => 1}

      discriminator_schema =
        build_discriminator_schema([wolf, dog, cat], :oneOf, String.to_atom(@discriminator), nil)

      assert {:error,
              [
                %OpenApiSpex.Cast.Error{
                  format: nil,
                  length: 5,
                  meta: %{},
                  name: nil,
                  path: [:breed],
                  reason: :min_length,
                  type: nil,
                  value: "pug"
                }
              ]} = cast(value: input_value, schema: discriminator_schema)
    end

    test "value is not an object", %{schemas: %{dog: dog, wolf: wolf, cat: cat}} do
      input_value = "this is a string but discriminator only works on objects"

      discriminator_schema =
        build_discriminator_schema([dog, wolf, cat], :anyOf, String.to_atom(@discriminator), nil)

      assert {:error, [error]} = cast(value: input_value, schema: discriminator_schema)
      assert error.reason == :invalid_type
      assert error.type == :object
      assert error.value == input_value
    end

    test "invalid property on discriminator schema", %{
      schemas: %{dog: dog, wolf: wolf}
    } do
      # "Pug" will fail because the `breed` property for a Wolf must have a minimum
      # length of 5.
      input_value = %{@discriminator => "Wolf", "breed" => "Pug", "age" => 1}

      # Create the discriminator schema. Discriminators require a composite
      # key be provided (`allOf`, `anyOf`, `oneOf`).
      discriminator_schema =
        build_discriminator_schema([dog, wolf], :anyOf, String.to_atom(@discriminator), nil)

      assert {:error, [error]} = cast(value: input_value, schema: discriminator_schema)
      assert error.reason == :min_length
    end

    test "invalid discriminator value", %{schemas: %{dog: dog}} do
      # Goats is not registered to any schema provided
      empty_discriminator_value = %{@discriminator => "Goats", "breed" => "Corgi", "age" => 1}

      discriminator_schema =
        build_discriminator_schema([dog], :anyOf, String.to_atom(@discriminator), nil)

      assert {:error, [error]} =
               cast(
                 value: empty_discriminator_value,
                 schema: discriminator_schema
               )

      assert error.reason == :invalid_discriminator_value
    end

    test "empty discriminator value", %{schemas: %{dog: dog}} do
      empty_discriminator_value = %{@discriminator => "", "breed" => "Corgi", "age" => 1}

      discriminator_schema =
        build_discriminator_schema([dog], :anyOf, String.to_atom(@discriminator), nil)

      assert {:error, [error]} =
               cast(
                 value: empty_discriminator_value,
                 schema: discriminator_schema
               )

      assert error.reason == :no_value_for_discriminator
    end

    test "nested, success", %{schemas: %{dog: dog, cat: cat}} do
      # "animal_type" is the discriminator and the keys need to be strings.
      input_value = %{"data" => %{@discriminator => "Dog", "breed" => "Corgi", "age" => 1}}
      # Nested schema to better simulate use with JSON API (real world)
      discriminator_schema = %Schema{
        title: "Nested Skemuh",
        type: :object,
        properties: %{
          data: build_discriminator_schema([dog, cat], :anyOf, String.to_atom(@discriminator), nil)
        }
      }

      # Note: We're expecting to getting atoms back, not strings
      expected = {:ok, %{data: %{age: 1, breed: "Corgi", animal_type: "Dog"}}}

      assert expected == cast_cast(value: input_value, schema: discriminator_schema)
    end

    test "nested, with invalid property on discriminator schema", %{
      schemas: %{dog: dog, wolf: wolf}
    } do
      # "animal_type" is the discriminator and the keys need to be strings.
      input_value = %{"data" => %{@discriminator => "Wolf", "breed" => "Pug", "age" => 1}}
      # Nested schema to better simulate use with JSON API (real world)
      discriminator_schema = %Schema{
        title: "Nested Skemuh",
        type: :object,
        properties: %{
          data: build_discriminator_schema([dog, wolf], :anyOf, String.to_atom(@discriminator), nil)
        }
      }

      assert {:error, [error]} = cast_cast(value: input_value, schema: discriminator_schema)

      # The format of the error path should be confirmed. This is just a guess.
      assert Error.message_with_path(error) ==
               "#/data/breed: String length is smaller than minLength: 5"
    end

    if Version.compare(System.version(), "1.10.0") in [:gt, :eq] do
      test "without setting a composite key, raises compile time error" do
        # While we're still specifying the composite key here, it'll be set to
        # nil. E.g. %Schema{anyOf: nil, discriminator: %{...}}
        discriminator_schema =
          build_discriminator_schema(nil, :anyOf, String.to_atom(@discriminator), nil)

        # We have to escape the map to unquote it later.
        schema_as_map = Map.from_struct(discriminator_schema) |> Macro.escape()

        # A module which will define our broken schema, and throw an error.
        code =
          quote do
            defmodule DiscriminatorWihoutCompositeKey do
              require OpenApiSpex

              OpenApiSpex.schema(unquote(schema_as_map))
            end
          end

        # Confirm we raise the error when we compile the code
        assert_raise(OpenApiSpex.SchemaException, fn ->
          Code.eval_quoted(code)
        end)
      end
    end

    if Version.compare(System.version(), "1.10.0") in [:gt, :eq] do
      # From the OAS discriminator docs:
      #
      #   "[..] inline schema definitions, which do not have a given id,
      #   cannot be used in polymorphism."
      test "discriminator schemas without titles, raise compile time error", %{
        schemas: %{dog: dog, cat: cat}
      } do
        discriminator_schema =
          build_discriminator_schema(
            [cat, %{dog | title: nil}],
            :anyOf,
            String.to_atom(@discriminator),
            nil
          )

        # We have to escape the map to unquote it later.
        schema_as_map = Map.from_struct(discriminator_schema) |> Macro.escape()

        # A module which will define our broken schema, and throw an error.
        code =
          quote do
            defmodule DiscriminatorSchemaWithoutId do
              require OpenApiSpex

              OpenApiSpex.schema(unquote(schema_as_map))
            end
          end

        # Confirm we raise the error when we compile the code
        assert_raise(OpenApiSpex.SchemaException, fn ->
          Code.eval_quoted(code)
        end)
      end
    end
  end
end
