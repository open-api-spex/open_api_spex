defmodule PhoenixApp.Accounts.User do
  use Ecto.Schema
  alias __MODULE__

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    timestamps()
  end

  def changeset(data \\ %User{}, params) do
    data
    |> Ecto.Changeset.cast(params, [:name, :email])
    |> Ecto.Changeset.validate_required([:name, :email])
  end
end
