defmodule PWeb.API.Resources.CollectionBase do
  alias P.Collection
  alias PWeb.API.Resources.Helpers

  @fields [:id, :title, :description]

  def build(%Collection{} = collection) do
    collection
    |> Map.take(@fields)
    |> Map.merge(%{
      inserted_at: Helpers.datetime_to_iso!(collection.inserted_at),
      updated_at: Helpers.datetime_to_iso!(collection.updated_at)
    })
  end
end
