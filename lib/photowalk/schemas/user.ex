defmodule P.User do
  use P.Schema
  import Ecto.Changeset

  alias P.Member

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:confirmed_at, :utc_datetime_usec)

    has_many :collection_memberships, Member, foreign_key: :user_id
    has_many :sent_collection_invitations, Member, foreign_key: :inviter_id

    timestamps()
  end

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
