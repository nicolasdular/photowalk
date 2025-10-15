defmodule P.Collection do
  @moduledoc """
  Represents a collection of photos that can be shared among multiple users.
  """

  use P.Schema
  import Ecto.Changeset

  alias P.{Member, Photo, User}

  schema "collections" do
    field :title, :string
    field :description, :string

    belongs_to :owner, User
    has_many :photos, Photo
    has_many :members, Member
    has_many :shared_users, through: [:members, :user]

    timestamps()
  end

  @cast_fields [:title, :description, :owner_id]
  @required_fields [:title, :owner_id]

  @doc false
  def changeset(collection, attrs) do
    collection
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:owner)
  end
end
