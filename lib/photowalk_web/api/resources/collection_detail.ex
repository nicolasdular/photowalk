defmodule PWeb.API.Resources.CollectionDetail do
  @moduledoc """
  API representation for a collection including its full set of photos.
  """

  alias Ecto.{Association.NotLoaded, UUID}
  alias OpenApiSpex.Schema
  alias P.Collection
  alias PWeb.API.Resources.{CollectionBase, PhotoDetail}

  @derive {Jason.Encoder, only: [:id, :title, :description, :inserted_at, :updated_at, :photos]}
  @enforce_keys [:id, :title, :inserted_at, :updated_at, :photos]
  defstruct [:id, :title, :description, :inserted_at, :updated_at, photos: []]

  @type t :: %__MODULE__{
          id: UUID.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          inserted_at: String.t(),
          updated_at: String.t(),
          photos: [PhotoDetail.t()]
        }

  @spec from_collection(Collection.t(), keyword()) :: t()
  def from_collection(%Collection{} = collection, opts \\ []) do
    base = CollectionBase.build(collection)
    current_user = Keyword.get(opts, :current_user)

    photos =
      collection
      |> fetch_loaded_photos!()
      |> Enum.map(&PhotoDetail.serialize(&1, current_user: current_user))

    struct!(__MODULE__, Map.put(base, :photos, photos))
  end

  defp fetch_loaded_photos!(%Collection{photos: %NotLoaded{}}) do
    raise ArgumentError,
          "expected collection.photos to be preloaded when building a CollectionDetail resource"
  end

  defp fetch_loaded_photos!(%Collection{photos: nil}), do: []
  defp fetch_loaded_photos!(%Collection{photos: photos}) when is_list(photos), do: photos

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
        photos: %Schema{
          type: :array,
          items: PhotoDetail.schema()
        }
      }
    }
  end
end
