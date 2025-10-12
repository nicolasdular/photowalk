defmodule P.Collections do
  @moduledoc """
  The Collections context for managing photo collections.
  """

  import Ecto.Query, warn: false

  alias P.{Collection, Repo, User}

  @spec list_collections_for_user(User.t()) :: [Collection.t()]
  def list_collections_for_user(%User{id: user_id}, opts \\ %{}) do
    # For now, only show collections owned by the user
    # In the future, this will include collections the user is invited to
    Collection
    |> where([c], c.owner_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> maybe_preload(opts[:preloads])
    |> Repo.all()
  end

  @spec create_collection(User.t(), map()) :: {:ok, Collection.t()} | {:error, Ecto.Changeset.t()}
  def create_collection(%User{} = user, attrs) do
    %Collection{}
    |> Collection.changeset(Map.put(attrs, "owner_id", user.id))
    |> Repo.insert()
  end

  @spec get_collection(integer()) :: Collection.t() | nil
  def get_collection(id) when is_integer(id) do
    Repo.get(Collection, id)
  end

  @spec get_collection_for_user(integer(), User.t()) ::
          {:ok, Collection.t()} | {:error, :not_found}
  def get_collection_for_user(id, %User{id: user_id}) when is_integer(id) do
    # For now, only allow access to owned collections
    # In the future, this will include collections the user is invited to
    case Collection
         |> where([c], c.id == ^id and c.owner_id == ^user_id)
         |> preload(:photos)
         |> Repo.one() do
      nil -> {:error, :not_found}
      collection -> {:ok, collection}
    end
  end

  @spec user_owns_collection?(User.t(), integer()) ::
          {:ok, true} | {:error, :not_found | :forbidden}
  def user_owns_collection?(%User{id: user_id}, collection_id) when is_integer(collection_id) do
    case get_collection(collection_id) do
      nil ->
        {:error, :not_found}

      %Collection{owner_id: ^user_id} ->
        {:ok, true}

      _collection ->
        {:error, :forbidden}
    end
  end

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads) when is_list(preloads), do: preload(query, ^preloads)
  defp maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)
end
