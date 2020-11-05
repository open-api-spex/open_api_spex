defmodule OpenApiSpex.Info do
  @moduledoc """
  Defines the `OpenApiSpex.Info.t` type.
  """
  alias OpenApiSpex.{Contact, License}
  @enforce_keys [:title, :version]
  defstruct [
    :title,
    :description,
    :termsOfService,
    :contact,
    :license,
    :version,
    :extensions
  ]

  @typedoc """
  [Info Object](https://swagger.io/specification/#infoObject)

  The object provides metadata about the API. The metadata MAY be used by the clients if needed,
  and MAY be presented in editing or documentation generation tools for convenience.
  """
  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t() | nil,
          termsOfService: String.t() | nil,
          contact: Contact.t() | nil,
          license: License.t() | nil,
          version: String.t(),
          extensions: %{String.t() => any()} | nil
        }
end
