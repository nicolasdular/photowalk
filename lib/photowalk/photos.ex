defmodule P.Photos do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias P.{Collections, Collection, Photo, Repo, Scope, User}
  alias P.Photos.Uploader

  @type upload_param :: Plug.Upload.t()
  @type photo_params :: %{optional(atom() | String.t()) => any()}

  @spec list_photos_for_user(User.t()) :: [Photo.t()]
  def list_photos_for_user(%User{id: user_id}) do
    Photo
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  @spec create_photo(Scope.t(), upload_param() | nil, photo_params()) ::
          {:ok, Photo.t()} | {:error, Changeset.t()}
  def create_photo(scope, upload, params \\ %{})

  def create_photo(%Scope{current_user: user} = scope, %Plug.Upload{} = upload, params) do
    collection_id = params["collection_id"] || params[:collection_id]

    with :ok <- validate_collection_access(scope, collection_id) do
      %Photo{}
      |> Photo.changeset(%{
        image: upload,
        source_filename: upload.filename,
        content_type: upload.content_type,
        title: upload.filename,
        user_id: user.id,
        collection_id: collection_id
      })
      |> Repo.insert()
    end
  end

  def create_photo(%Scope{}, nil, _params) do
    {:error, Changeset.add_error(%Changeset{}, :photo, "must include a file")}
  end

  def create_photo(%Scope{}, _invalid_upload, _params) do
    {:error, Changeset.add_error(%Changeset{}, :photo, "invalid file")}
  end

  @spec delete_photo(User.t(), String.t() | String.t()) ::
          {:ok, Photo.t()} | {:error, :not_found | Ecto.Changeset.t()}
  def delete_photo(%User{id: user_id}, photo_id) do
    with {:ok, id} <- {:ok, photo_id},
         %Photo{} = photo <- fetch_photo_for_user(user_id, id),
         {:ok, deleted_photo} <- Repo.delete(photo) do
      maybe_delete_upload(deleted_photo)
      {:ok, deleted_photo}
    else
      {:error, :invalid_id} -> {:error, :not_found}
      nil -> {:error, :not_found}
      {:error, _} = error -> error
    end
  end

  def thumnbnails_for(%Collection{id: collection_id}) do
    Photo
    |> where([p], p.collection_id == ^collection_id)
    |> order_by([p], desc: p.inserted_at)
    |> limit(4)
    |> Repo.all()
  end

  def like_photo(%Scope{} = scope, photo_id) do
    # TODO: implement check if user has access to that photo

    with photo when not is_nil(photo) <- Repo.get(Photo, photo_id) do
      P.PhotoLike.changeset(%P.PhotoLike{}, %{user_id: scope.current_user.id, photo_id: photo.id})
      |> Repo.insert()
      |> case do
        {:ok, _like} ->
          :ok

        {:error,
         %Ecto.Changeset{
           errors: [
             photo_id: {_, [constraint: :unique, constraint_name: "photo_likes_photo_id_user_id_index"]}
           ]
         } = _changeset} ->
          # User already liked the photo, return ok without error
          :ok

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      nil -> {:error, :not_found}
    end
  end

  def unlike_photo(%Scope{} = scope, photo_id) do
    case Repo.get_by(P.PhotoLike, user_id: scope.current_user.id, photo_id: photo_id) do
      nil ->
        :ok

      like ->
        Repo.delete(like)
        :ok
    end
  end

  defp validate_collection_access(_scope, nil), do: :ok

  defp validate_collection_access(scope, collection_id) do
    case Repo.get(Collection, collection_id) do
      nil ->
        changeset = Changeset.add_error(%Changeset{}, :collection_id, "does not exist")
        {:error, changeset}

      collection ->
        if Collections.can_read_collection?(scope, collection) do
          :ok
        else
          changeset = Changeset.add_error(%Changeset{}, :collection_id, "you don't have access to this collection")
          {:error, changeset}
        end
    end
  end

  defp fetch_photo_for_user(user_id, photo_id) do
    Photo
    |> where([p], p.id == ^photo_id and p.user_id == ^user_id)
    |> Repo.one()
  end

  defp maybe_delete_upload(%Photo{image: nil}), do: :ok

  defp maybe_delete_upload(%Photo{} = photo) do
    try do
      Uploader.delete({photo.image, photo})
    rescue
      _ -> :ok
    end

    :ok
  end
end
