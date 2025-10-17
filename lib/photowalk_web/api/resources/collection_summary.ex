defmodule PWeb.API.Resources.CollectionSummary do
  @moduledoc """
  API representation for a collection in listings.
  """

  alias Ecto.UUID
  alias OpenApiSpex.Schema
  alias P.{Collection, Photos}
  alias PWeb.API.Resources.{CollectionBase, PhotoSummary}

  @derive {Jason.Encoder, only: [:id, :title, :description, :inserted_at, :updated_at, :thumbnails]}
  @enforce_keys [:id, :title, :inserted_at, :updated_at, :thumbnails]
  defstruct [:id, :title, :description, :inserted_at, :updated_at, thumbnails: []]

  @type t :: %__MODULE__{
          id: UUID.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          inserted_at: String.t(),
          updated_at: String.t(),
          thumbnails: [PhotoSummary.t()]
        }

  @spec from_collection(Collection.t(), keyword()) :: t()
  def from_collection(%Collection{} = collection, opts \\ []) do
    base = CollectionBase.build(collection)
    current_user = Keyword.get(opts, :current_user)

    thumbnails =
      collection
      |> Photos.thumnbnails_for()
      |> Enum.map(&PhotoSummary.serialize(&1, current_user: current_user))

    struct!(__MODULE__, Map.put(base, :thumbnails, thumbnails))
  end

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
end
