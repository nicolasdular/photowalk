defmodule PWeb.API.Resources.CollectionBase do
  @moduledoc false

  alias P.Collection
  alias PWeb.API.Resources.Helpers

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
