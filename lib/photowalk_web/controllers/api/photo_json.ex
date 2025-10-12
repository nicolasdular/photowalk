defmodule PWeb.PhotoJSON do
  alias P.Photo

  def index(%{photos: photos} = assigns) do
    %{data: Enum.map(photos, &data(&1, assigns))}
  end

  def show(%{photo: photo} = assigns) do
    %{data: data(photo, assigns)}
  end

  def fields do
    [:id, :title, :full_url, :thumbnail_url, :inserted_at, :updated_at]
  end

  def required_fields, do: [:id, :title, :thumbnail_url, :full_url]

  @doc """
  Converts a Photo struct to a map representation.
  Public function to allow reuse in other JSON modules.
  """
  def data(%Photo{} = photo, assigns \\ %{}) do
    assigns = Map.new(assigns)

    %{
      id: photo.id,
      thumbnail_url: Photo.url(photo, :thumb),
      full_url: Photo.url(photo, :full),
      inserted_at: format_datetime(photo.inserted_at),
      updated_at: format_datetime(photo.updated_at),
      title: photo.title,
      allowed_to_delete: allowed_to_delete?(photo, assigns)
    }
  end

  defp allowed_to_delete?(photo, assigns) do
    case Map.get(assigns, :current_user) do
      %{id: user_id} when user_id == photo.user_id -> true
      _ -> false
    end
  end

  defp format_datetime(%NaiveDateTime{} = naive) do
    naive
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp format_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
