defmodule PWeb.CollectionJSON do
  alias P.Collection
  alias PWeb.PhotoJSON

  def index(%{collections: collections}) do
    %{data: Enum.map(collections, &data/1)}
  end

  def show(%{collection: collection}) do
    %{data: data(collection)}
  end

  def fields do
    [:id, :title, :description, :inserted_at, :updated_at]
  end

  def required_fields, do: [:id, :title]

  defp data(%Collection{} = collection) do
    base_data = %{
      id: collection.id,
      title: collection.title,
      description: collection.description,
      inserted_at: format_datetime(collection.inserted_at),
      updated_at: format_datetime(collection.updated_at)
    }

    # Include photos if they're preloaded
    case collection do
      %{photos: %Ecto.Association.NotLoaded{}} ->
        base_data

      %{photos: photos} when is_list(photos) ->
        Map.put(base_data, :photos, Enum.map(photos, &PhotoJSON.data/1))

      _ ->
        base_data
    end
  end

  defp format_datetime(%NaiveDateTime{} = naive) do
    naive
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp format_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
