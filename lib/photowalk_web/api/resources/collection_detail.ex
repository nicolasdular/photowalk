defmodule PWeb.API.Resources.CollectionDetail do
  alias Ecto.{Association.NotLoaded}
  alias OpenApiSpex.Schema
  alias P.Collection
  alias PWeb.API.Resources.{CollectionBase, PhotoDetail}

  def schema do
    %Schema{
      title: "CollectionDetail",
      description: "Collection data returned from show/create/update endpoints",
      type: :object,
      required: [:id, :title, :inserted_at, :updated_at, :photos],
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        title: %Schema{type: :string},
        description: %Schema{type: :string, nullable: true},
        inserted_at: %Schema{type: :string, format: :"date-time"},
        updated_at: %Schema{type: :string, format: :"date-time"},
        can_edit: %Schema{type: :boolean},
        photos: %Schema{
          type: :array,
          items: PhotoDetail.schema()
        }
      }
    }
  end

  def build(%Collection{} = collection, opts \\ []) do
    current_user = Keyword.get(opts, :current_user)

    photos =
      collection
      |> fetch_loaded_photos!()
      |> Enum.map(&PhotoDetail.build(&1, current_user: current_user))

    CollectionBase.build(collection)
    |> Map.put(:can_edit, collection.owner_id == current_user.id)
    |> Map.put(:photos, photos)
  end

  defp fetch_loaded_photos!(%Collection{photos: %NotLoaded{}}) do
    raise ArgumentError,
          "expected collection.photos to be preloaded when building a CollectionDetail resource"
  end

  defp fetch_loaded_photos!(%Collection{photos: nil}), do: []
  defp fetch_loaded_photos!(%Collection{photos: photos}) when is_list(photos), do: photos
end
