defmodule P.Photos do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias P.{Photo, Repo, User}

  @type upload_param :: Plug.Upload.t()

  @spec list_photos_for_user(User.t()) :: [Photo.t()]
  def list_photos_for_user(%User{id: user_id}) do
    Photo
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  @spec create_photo(User.t(), upload_param() | nil) :: {:ok, Photo.t()} | {:error, term()}
  def create_photo(%User{} = user, %Plug.Upload{} = upload) do
    insert_photo(user, upload)
  end

  def create_photo(%User{}, nil),
    do: {:error, Ecto.Changeset.add_error(%Changeset{}, :photo, "must include a file")}

  def create_photo(%User{}, _),
    do: {:error, Ecto.Changeset.add_error(%Changeset{}, :photo, "invalid file")}

  def create_photo(_, _), do: {:error, :no_file}

  @spec insert_photo(User.t(), Plug.Upload.t()) :: {:ok, Photo.t()} | {:error, Changeset.t()}
  defp insert_photo(%User{} = user, %Plug.Upload{} = upload) do
    %Photo{}
    |> Photo.changeset(%{
      image: upload,
      source_filename: upload.filename,
      content_type: upload.content_type,
      title: upload.filename,
      user_id: user.id
    })
    |> Repo.insert()
  end
end
