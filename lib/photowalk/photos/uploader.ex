defmodule P.Photos.Uploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  alias Waffle.File
  alias P.Photo
  alias Image

  @extension_whitelist ~w(.jpg .jpeg .png .heic .heif .webp)
  @thumbnail_dimensions %{full: 2048, thumb: 1024}
  @versions Map.keys(@thumbnail_dimensions)
  @quality 90

  def validate({%File{file_name: file_name}, _scope}) do
    if String.downcase(Path.extname(file_name)) in @extension_whitelist do
      :ok
    else
      {:error, "unsupported file extension"}
    end
  end

  def storage_dir(_version, {_file, %Photo{user_id: user_id, upload_key: upload_key}}) do
    Path.join(["uploads", "users", to_string(user_id), upload_key])
  end

  def filename(version, _file_and_scope), do: version

  def transform(version, _) when version in @versions do
    {&transform_version(version, &1, &2), &extension/2}
  end

  defp extension(_version, _file), do: "jpg"

  defp transform_version(version, _waffle_version, %File{} = file) do
    size = Map.fetch!(@thumbnail_dimensions, version)
    process_image(file, fn path -> Image.thumbnail!(path, size) end)
  end

  defp process_image(%File{} = file, operation) when is_function(operation, 1) do
    destination = File.generate_temporary_path(".jpg")

    try do
      image = operation.(file.path)
      Image.write!(image, destination, quality: @quality)

      updated =
        %File{
          file
          | path: destination,
            file_name: Path.basename(destination),
            is_tempfile?: true
        }

      {:ok, updated}
    rescue
      exception ->
        {:error, Exception.message(exception)}
    end
  end
end
