defmodule P.Photo do
  @moduledoc """
  Represents a processed photo belonging to a user.
  """

  use P.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  alias P.Photos.Uploader
  alias P.User
  alias P.Collection

  schema "photos" do
    field :upload_key, Ecto.UUID
    field :image, Uploader.Type
    field :source_filename, :string
    field :content_type, :string
    field :title, :string

    field :full_url, :string, virtual: true
    field :thumbnail_url, :string, virtual: true

    belongs_to :user, User
    belongs_to :collection, Collection

    timestamps()
  end

  @cast_fields [:source_filename, :content_type, :user_id, :title, :collection_id]

  @doc false
  def changeset(photo, attrs) do
    photo
    |> cast(attrs, @cast_fields)
    |> maybe_put_upload_key()
    |> cast_attachments(attrs, [:image])
    |> validate_required([:user_id, :upload_key, :image, :title])
    |> assoc_constraint(:user)
    |> assoc_constraint(:collection)
    |> unique_constraint(:upload_key)
  end

  def with_urls(%__MODULE__{} = photo) do
    photo
    |> Map.put(:full_url, url(photo, :full))
    |> Map.put(:thumbnail_url, url(photo, :thumb))
  end

  def url(%__MODULE__{} = photo, version) when version in [:full, :thumb] do
    photo
    |> uploader_tuple()
    |> Uploader.url(version)
  end

  defp uploader_tuple(%__MODULE__{} = photo) do
    {photo.image, photo}
  end

  defp maybe_put_upload_key(changeset) do
    {_, value} = fetch_field(changeset, :upload_key)

    if value do
      changeset
    else
      put_change(changeset, :upload_key, Ecto.UUID.generate())
    end
  end
end
