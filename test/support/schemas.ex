defmodule OpenApiSpexTest.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule User do
    OpenApiSpex.schema %{
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        name:  %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
        email: %Schema{type: :string, description: "Email address", format: :email},
        inserted_at: %Schema{type: :string, description: "Creation timestamp", format: :'date-time'},
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :'date-time'}
      },
      required: [:name, :email],
      additionalProperties: false,
      example: %{
        "id" => 123,
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "inserted_at" => "2017-09-12T12:34:55Z",
        "updated_at" => "2017-09-13T10:11:12Z"
      }
    }
  end

  defmodule ContactInfo do
    OpenApiSpex.schema %{
      title: "ContactInfo",
      description: "A users contact information",
      type: :object,
      properties: %{
        phone_number: %Schema{type: :string, description: "Phone number"},
        postal_address: %Schema{type: :string, description: "Postal address"}
      },
      required: [:phone_number],
      additionalProperties: false,
      example: %{
        "phone_number" => "555-123-456",
        "postal_address" => "123 Evergreen Tce"
      }
    }
  end

  defmodule CreditCardPaymentDetails do
    OpenApiSpex.schema %{
      title: "CreditCardPaymentDetails",
      description: "Payment details when using credit-card method",
      type: :object,
      properties: %{
        credit_card_number: %Schema{type: :string, description: "Credit card number"},
        name_on_card: %Schema{type: :string, description: "Name as appears on card"},
        expiry: %Schema{type: :string, description: "4 digit expiry MMYY"}
      },
      required: [:credit_card_number, :name_on_card, :expiry],
      example: %{
        "credit_card_number" => "1234-5678-1234-6789",
        "name_on_card" => "Joe User",
        "expiry" => "1234"
      }
    }
  end

  defmodule DirectDebitPaymentDetails do
    OpenApiSpex.schema %{
      title: "DirectDebitPaymentDetails",
      description: "Payment details when using direct-debit method",
      type: :object,
      properties: %{
        account_number: %Schema{type: :string, description: "Bank account number"},
        account_name: %Schema{type: :string, description: "Name of account"},
        bsb: %Schema{type: :string, description: "Branch identifier"}
      },
      required: [:account_number, :account_name, :bsb],
      example: %{
        "account_number" => "12349876",
        "account_name" => "Joes Savings Account",
        "bsb" => "123-4567"
      }
    }
  end

  defmodule PaymentDetails do
    OpenApiSpex.schema %{
      title: "PaymentDetails",
      description: "Abstract Payment details type",
      type: :object,
      oneOf: [
        CreditCardPaymentDetails,
        DirectDebitPaymentDetails
      ]
    }
  end

  defmodule UserRequest do
    OpenApiSpex.schema %{
      title: "UserRequest",
      description: "POST body for creating a user",
      type: :object,
      properties: %{
        user: User
      },
      example: %{
        "user" => %{
          "name" => "Joe User",
          "email" => "joe@gmail.com"
        }
      }
    }
  end

  defmodule UserResponse do
    OpenApiSpex.schema %{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      },
      example: %{
        "data" => %{
          "id" => 123,
          "name" => "Joe User",
          "email" => "joe@gmail.com",
          "inserted_at" => "2017-09-12T12:34:55Z",
          "updated_at" => "2017-09-13T10:11:12Z"
        }
      }
    }
  end

  defmodule UsersResponse do
    OpenApiSpex.schema %{
      title: "UsersResponse",
      description: "Response schema for multiple users",
      type: :object,
      properties: %{
        data: %Schema{description: "The users details", type: :array, items: User}
      },
      example: %{
        "data" => [
          %{
            "id" => 123,
            "name" => "Joe User",
            "email" => "joe@gmail.com"
          },
          %{
            "id" => 456,
            "name" => "Jay Consumer",
            "email" => "jay@yahoo.com"
          }
        ]
      }
    }
  end

  defmodule EntityWithDict do
    OpenApiSpex.schema %{
      title: "EntityWithDict",
      description: "Entity with a dictionary defined via additionalProperties",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "Entity ID"},
        stringDict: %Schema{type: :object, description: "String valued dict", additionalProperties: %Schema{type: :string}},
        anyTypeDict: %Schema{type: :object, description: "Untyped valued dict", additionalProperties: true},
      },
      example: %{
        "id" => 123,
        "stringDict" => %{"key1" => "value1", "key2" => "value2"},
        "anyTypeDict" => %{"key1" => 42, "key2" => %{"foo" => "bar"}}
      }
    }
  end

  defmodule Pet do
    require OpenApiSpex

    alias OpenApiSpex.{Schema, Discriminator}

    OpenApiSpex.schema(%{
      title: "Pet",
      type: :object,
      properties: %{
        pet_type: %Schema{type: :string}
      },
      required: [:pet_type],
      discriminator: %Discriminator{
        propertyName: "pet_type"
      }
    })
  end

  defmodule Cat do
    require OpenApiSpex

    alias OpenApiSpex.Schema

    OpenApiSpex.schema(%{
      title: "Cat",
      type: :object,
      allOf: [
        Pet,
        %Schema{
          type: :object,
          properties: %{
            meow: %Schema{type: :string}
          },
          required: [:meow]
        }
      ]
    })
  end

  defmodule Dog do
    require OpenApiSpex

    alias OpenApiSpex.Schema

    OpenApiSpex.schema(%{
      title: "Dog",
      type: :object,
      allOf: [
        Pet,
        %Schema{
          type: :object,
          properties: %{
            bark: %Schema{type: :string}
          },
          required: [:bark]
        }
      ]
    })
  end

  defmodule CatOrDog do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "CatOrDog",
      oneOf: [Cat, Dog]
    })
  end
end
