defmodule OpenApiSpex.Info do
  alias OpenApiSpex.{Contact, License}
  @enforce_keys [:title, :version]
  defstruct [
    :title,
    :description,
    :termsOfService,
    :contact,
    :license,
    :version
  ]
  @type t :: %__MODULE__{
    title: String.t,
    description: String.t,
    termsOfService: String.t,
    contact: Contact.t,
    license: License.t,
    version: String.t
  }
end