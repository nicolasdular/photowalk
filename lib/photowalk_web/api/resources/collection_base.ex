defmodule PWeb.API.Resources.CollectionBase do
  @moduledoc false

  alias Ecto.UUID
  alias P.Collection
  alias PWeb.API.Resources.Helpers

  @type base_fields :: %{
          id: UUID.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          inserted_at: String.t(),
          updated_at: String.t()
        }

  @spec build(Collection.t()) :: base_fields()
  def build(%Collection{} = collection) do
    %{
      id: collection.id,
      title: collection.title,
      description: collection.description,
      inserted_at: Helpers.datetime_to_iso!(collection.inserted_at),
      updated_at: Helpers.datetime_to_iso!(collection.updated_at)
    }
  end
end
