defmodule Thexstack.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:confirmed_at, :utc_datetime_usec)

    has_many(:todos, Thexstack.Tasks.Todo)

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :confirmed_at])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
