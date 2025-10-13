defmodule P.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:confirmed_at, :utc_datetime_usec)

    field :avatar_url, :string, virtual: true

    timestamps()
  end

  def avatar_url(%__MODULE__{email: email}) when is_binary(email) do
    hash =
      :crypto.hash(:md5, String.downcase(String.trim(email)))
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}"
  end

  def avatar_url(_), do: nil

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :confirmed_at, :name])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
  end

  def magic_link_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :confirmed_at, :name])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
