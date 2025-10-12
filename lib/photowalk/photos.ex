defmodule P.Photos do
  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias P.{Collections, Collection, Photo, Repo, User}
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

  @spec create_photo(User.t(), upload_param() | nil, photo_params()) ::
          {:ok, Photo.t()} | {:error, term()}
  def create_photo(user, upload, params \\ %{})

  def create_photo(%User{} = user, %Plug.Upload{} = upload, params) do
    insert_photo(user, upload, params)
  end

  def create_photo(%User{}, nil, _params),
    do: {:error, Ecto.Changeset.add_error(%Changeset{}, :photo, "must include a file")}

  def create_photo(%User{}, _, _params),
    do: {:error, Ecto.Changeset.add_error(%Changeset{}, :photo, "invalid file")}

  def create_photo(_, _, _), do: {:error, :no_file}

  @spec delete_photo(User.t(), integer() | String.t()) ::
          {:ok, Photo.t()} | {:error, :not_found | Ecto.Changeset.t()}
  def delete_photo(%User{id: user_id}, photo_id) do
    with {:ok, id} <- normalize_photo_id(photo_id),
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

  @spec insert_photo(User.t(), Plug.Upload.t(), photo_params()) ::
          {:ok, Photo.t()} | {:error, Changeset.t()}
  defp insert_photo(%User{} = user, %Plug.Upload{} = upload, params) do
    collection_id = Map.get(params, "collection_id") || Map.get(params, :collection_id)

    attrs = %{
      image: upload,
      source_filename: upload.filename,
      content_type: upload.content_type,
      title: upload.filename,
      user_id: user.id
    }

    attrs =
      if collection_id do
        Map.put(attrs, :collection_id, collection_id)
      else
        attrs
      end

    changeset = Photo.changeset(%Photo{}, attrs)

    # Validate collection ownership if collection_id is provided
    changeset =
      if collection_id do
        validate_collection_ownership(changeset, user.id, collection_id)
      else
        changeset
      end

    Repo.insert(changeset)
  end

  defp validate_collection_ownership(changeset, user_id, collection_id) do
    user = %User{id: user_id}

    # Convert collection_id to integer if it's a string
    collection_id_int =
      case collection_id do
        id when is_integer(id) ->
          id

        id when is_binary(id) ->
          case Integer.parse(id) do
            {int, ""} -> int
            _ -> nil
          end

        _ ->
          nil
      end

    if is_nil(collection_id_int) do
      Changeset.add_error(changeset, :collection_id, "must be a valid integer")
    else
      case Collections.user_owns_collection?(user, collection_id_int) do
        {:ok, true} ->
          changeset

        {:error, :not_found} ->
          Changeset.add_error(changeset, :collection_id, "does not exist")

        {:error, :forbidden} ->
          Changeset.add_error(changeset, :collection_id, "does not belong to you")
      end
    end
  end

  defp normalize_photo_id(id) when is_integer(id) and id > 0, do: {:ok, id}

  defp normalize_photo_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} when int > 0 -> {:ok, int}
      _ -> {:error, :invalid_id}
    end
  end

  defp normalize_photo_id(_), do: {:error, :invalid_id}

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
