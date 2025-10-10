defmodule PWeb.PhotoJSON do
  alias P.Photo

  def index(%{photos: photos}) do
    %{data: Enum.map(photos, &data/1)}
  end

  def show(%{photo: photo}) do
    %{data: data(photo)}
  end

  def fields do
    [:id, :title, :full_url, :thumbnail_url, :inserted_at, :updated_at]
  end

  def required_fields, do: [:id, :title, :thumbnail_url, :full_url]

  @doc """
  Converts a Photo struct to a map representation.
  Public function to allow reuse in other JSON modules.
  """
  def data(%Photo{} = photo) do
    %{
      id: photo.id,
      thumbnail_url: Photo.url(photo, :thumb),
      full_url: Photo.url(photo, :full),
      inserted_at: format_datetime(photo.inserted_at),
      updated_at: format_datetime(photo.updated_at),
      title: photo.title
    }
  end

  defp format_datetime(%NaiveDateTime{} = naive) do
    naive
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp format_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
