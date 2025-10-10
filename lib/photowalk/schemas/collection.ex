defmodule P.Collection do
  @moduledoc """
  Represents a collection of photos that can be shared among multiple users.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias P.{Photo, User}

  schema "collections" do
    field :title, :string
    field :description, :string

    belongs_to :owner, User
    has_many :photos, Photo

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
