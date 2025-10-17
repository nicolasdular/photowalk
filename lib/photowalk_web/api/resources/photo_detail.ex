defmodule PWeb.API.Resources.PhotoDetail do
  @moduledoc """
  API transport representation for a photo with author information.
  """

  alias Ecto.UUID
  alias OpenApiSpex.Schema
  alias P.{Photo, User}
  alias PWeb.API.Resources.PhotoSummary
  alias PWeb.API.Resources.User, as: UserResource

  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :thumbnail_url,
             :full_url,
             :inserted_at,
             :updated_at,
             :allowed_to_delete,
             :user
           ]}
  @enforce_keys [
    :id,
    :title,
    :thumbnail_url,
    :full_url,
    :inserted_at,
    :updated_at,
    :allowed_to_delete,
    :user
  ]
  defstruct [
    :id,
    :title,
    :thumbnail_url,
    :full_url,
    :inserted_at,
    :updated_at,
    :allowed_to_delete,
    :user
  ]

  @type t :: %__MODULE__{
          id: UUID.t(),
          title: String.t() | nil,
          thumbnail_url: String.t(),
          full_url: String.t(),
          inserted_at: String.t(),
          updated_at: String.t(),
          allowed_to_delete: boolean(),
          user: UserResource.t()
        }

  @spec serialize(Photo.t(), keyword()) :: t()
  def serialize(%Photo{} = photo, opts \\ []) do
    %User{} = user = ensure_user_preloaded(photo)
    summary = PhotoSummary.serialize(photo, opts)

    %__MODULE__{
      id: summary.id,
      title: summary.title,
      thumbnail_url: summary.thumbnail_url,
      full_url: summary.full_url,
      inserted_at: summary.inserted_at,
      updated_at: summary.updated_at,
      allowed_to_delete: summary.allowed_to_delete,
      user: UserResource.serialize(user)
    }
  end

  defp ensure_user_preloaded(%Photo{user: %User{} = user}), do: user

  defp ensure_user_preloaded(%Photo{}) do
    raise ArgumentError,
          "expected photo.user to be preloaded when building a PhotoDetail resource"
  end

  def schema do
    %Schema{
      title: "PhotoDetail",
      description: "Detailed representation of a photo including author information",
      allOf: [
        PhotoSummary.schema(),
        %Schema{
          type: :object,
          required: [:user],
          properties: %{
            user: UserResource.schema()
          }
        }
      ]
    }
  end
end
