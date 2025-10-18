defmodule P.PhotoLike do
  use P.Schema
  import Ecto.Changeset
  alias P.{User, Photo}

  schema "photo_likes" do
    belongs_to :user, User
    belongs_to :photo, Photo

    timestamps()
  end

  def changeset(photo_like, attrs) do
    photo_like
    |> cast(attrs, [:user_id, :photo_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:photo)
    |> validate_required([:user_id, :photo_id])
    |> unique_constraint(:photo_id, name: :photo_likes_photo_id_user_id_index)
  end
end
