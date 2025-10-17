defmodule PWeb.API.Resources.PhotoSummary do
  @moduledoc """
  API transport representation for a photo when embedded as a summary.
  """

  alias Ecto.UUID
  alias OpenApiSpex.Schema
  alias P.Photo
  alias PWeb.API.Resources.Helpers

  @derive {Jason.Encoder, only: [:id, :title, :thumbnail_url, :full_url, :inserted_at, :updated_at, :allowed_to_delete]}
  @enforce_keys [
    :id,
    :title,
    :thumbnail_url,
    :full_url,
    :inserted_at,
    :updated_at,
    :allowed_to_delete
  ]
  defstruct [
    :id,
    :title,
    :thumbnail_url,
    :full_url,
    :inserted_at,
    :updated_at,
    :allowed_to_delete
  ]

  @type t :: %__MODULE__{
          id: UUID.t(),
          title: String.t() | nil,
          thumbnail_url: String.t(),
          full_url: String.t(),
          inserted_at: String.t(),
          updated_at: String.t(),
          allowed_to_delete: boolean()
        }

  @spec from_photo(Photo.t(), keyword()) :: t()
  def from_photo(%Photo{} = photo, opts \\ []) do
    current_user = Keyword.get(opts, :current_user)

    %__MODULE__{
      id: photo.id,
      title: photo.title,
      thumbnail_url: Photo.url(photo, :thumb),
      full_url: Photo.url(photo, :full),
      inserted_at: Helpers.datetime_to_iso!(photo.inserted_at),
      updated_at: Helpers.datetime_to_iso!(photo.updated_at),
      allowed_to_delete: allowed_to_delete?(photo, current_user)
    }
  end

  defp allowed_to_delete?(%Photo{user_id: user_id}, %{id: user_id}), do: true
  defp allowed_to_delete?(_photo, _current_user), do: false

  def schema do
    %Schema{
      title: "PhotoSummary",
      description: "Summary representation of a photo",
      type: :object,
      required: [:id, :title, :thumbnail_url, :full_url, :inserted_at, :updated_at, :allowed_to_delete],
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        title: %Schema{type: :string},
        thumbnail_url: %Schema{type: :string, format: :uri},
        full_url: %Schema{type: :string, format: :uri},
        inserted_at: %Schema{type: :string, format: :"date-time"},
        updated_at: %Schema{type: :string, format: :"date-time"},
        allowed_to_delete: %Schema{type: :boolean}
      }
    }
  end
end
