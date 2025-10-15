defmodule P.Member do
  use P.Schema
  import Ecto.Changeset

  alias P.{Collection, User}

  schema "members" do
    belongs_to :user, User
    belongs_to :collection, Collection
    belongs_to :inviter, User

    timestamps()
  end

  @fields [:user_id, :collection_id, :inviter_id]

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, @fields)
    |> validate_required(@fields -- [:inviter_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:collection)
    |> assoc_constraint(:inviter)
    |> unique_constraint([:user_id, :collection_id],
      name: :members_user_id_collection_id_index,
      message: "is already a member"
    )
  end
end
