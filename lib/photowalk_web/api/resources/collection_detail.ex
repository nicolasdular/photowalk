defmodule PWeb.API.Resources.CollectionDetail do
  alias OpenApiSpex.Schema
  alias P.Collection
  alias PWeb.API.Resources.{CollectionBase, PhotoDetail}

  def preload(_opts), do: [photos: [:user, likes: :user]]

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
      collection.photos
      |> Enum.map(&PhotoDetail.build(&1, opts))

    CollectionBase.build(collection)
    |> Map.put(:can_edit, collection.owner_id == current_user.id)
    |> Map.put(:photos, photos)
  end
end
