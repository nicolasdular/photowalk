defmodule PWeb.CollectionJSON do
  alias P.Collection
  alias PWeb.PhotoJSON

  def index(%{collections: collections} = assigns) do
    %{data: Enum.map(collections, &index_data(&1, assigns))}
  end

  def show(%{collection: collection} = assigns) do
    %{data: data(collection, assigns)}
  end

  def fields do
    [:id, :title, :description, :inserted_at, :updated_at]
  end

  def required_fields, do: [:id, :title]

  defp index_data(collection, assigns) do
    base_data(collection)
    |> Map.put(
      :thumbnails,
      Enum.map(P.Photos.thumnbnails_for(collection), &PhotoJSON.data(&1, Map.new(assigns)))
    )
  end

  defp data(%Collection{} = collection, assigns) do
    assigns = Map.new(assigns)
    base_data = base_data(collection)

    # Include photos if they're preloaded
    case collection do
      %{photos: %Ecto.Association.NotLoaded{}} ->
        base_data

      %{photos: photos} when is_list(photos) ->
        Map.put(base_data, :photos, Enum.map(photos, &PhotoJSON.data(&1, assigns)))

      _ ->
        base_data
    end
  end

  defp base_data(%Collection{} = collection) do
    %{
      id: collection.id,
      title: collection.title,
      description: collection.description,
      inserted_at: format_datetime(collection.inserted_at),
      updated_at: format_datetime(collection.updated_at)
    }
  end

  defp format_datetime(%NaiveDateTime{} = naive) do
    naive
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp format_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
