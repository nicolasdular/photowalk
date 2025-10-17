defmodule PWeb.API.Resources.CollectionSummary do
  alias OpenApiSpex.Schema
  alias P.{Collection, Photos}
  alias PWeb.API.Resources.{CollectionBase, PhotoSummary}

  def schema do
    %Schema{
      title: "CollectionSummary",
      description: "Collection data used in list endpoints",
      type: :object,
      required: [:id, :title, :inserted_at, :updated_at, :thumbnails],
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        title: %Schema{type: :string},
        description: %Schema{type: :string, nullable: true},
        inserted_at: %Schema{type: :string, format: :"date-time"},
        updated_at: %Schema{type: :string, format: :"date-time"},
        thumbnails: %Schema{
          type: :array,
          items: PhotoSummary.schema(),
          description: "Up to four most recent photos in the collection"
        }
      }
    }
  end

  def build(%Collection{} = collection, opts \\ []) do
    base = CollectionBase.build(collection)
    current_user = Keyword.get(opts, :current_user)

    thumbnails =
      collection
      |> Photos.thumnbnails_for()
      |> Enum.map(&PhotoSummary.build(&1, current_user: current_user))

    base |> Map.put(:thumbnails, thumbnails)
  end
end
