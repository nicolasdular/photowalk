defmodule PWeb.CollectionJSON do
  alias P.Collection

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
