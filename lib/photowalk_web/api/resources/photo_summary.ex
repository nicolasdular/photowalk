defmodule PWeb.API.Resources.PhotoSummary do
  alias OpenApiSpex.Schema
  alias P.Photo
  alias PWeb.API.Resources.Helpers

  use PWeb.API.Resource

  @fields [
    :id,
    :title,
    :thumbnail_url,
    :full_url,
    :inserted_at,
    :updated_at,
    :allowed_to_delete
  ]

  def build(%Photo{} = photo, opts \\ []) do
    current_user = Keyword.get(opts, :current_user)

    Map.take(photo, [:id, :title])
    |> Map.merge(%{
      thumbnail_url: Photo.url(photo, :thumb),
      full_url: Photo.url(photo, :full),
      inserted_at: Helpers.datetime_to_iso!(photo.inserted_at),
      updated_at: Helpers.datetime_to_iso!(photo.updated_at),
      allowed_to_delete: allowed_to_delete?(photo, current_user)
    })
  end

  defp allowed_to_delete?(%Photo{user_id: user_id}, %{id: user_id}), do: true
  defp allowed_to_delete?(_photo, _current_user), do: false

  def schema do
    %Schema{
      title: "PhotoSummary",
      type: :object,
      required: @fields,
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
