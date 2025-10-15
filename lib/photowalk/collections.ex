defmodule P.Collections do
  @moduledoc """
  The Collections context for managing photo collections.
  """

  import Ecto.Query, warn: false

  alias P.{Collection, Member, Repo, User}

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
    Repo.transaction(fn ->
      with {:ok, collection} <-
             %Collection{}
             |> Collection.changeset(Map.put(attrs, "owner_id", user.id))
             |> Repo.insert(),
           {:ok, _member} <- create_owner_member(user, collection) do
        {:ok, collection}
      else
        error -> Repo.rollback(error)
      end
    end)
    |> case do
      {:ok, {:ok, collection}} -> {:ok, collection}
      {:error, error} -> error
    end
  end

  defp create_owner_member(user, collection) do
    %Member{}
    |> Member.changeset(%{
      user_id: user.id,
      collection_id: collection.id,
      inviter_id: nil
    })
    |> Repo.insert()
  end

  @spec get_collection(String.t()) :: Collection.t() | nil
  def get_collection(id) do
    Repo.get(Collection, id)
  end

  @spec get_collection_for_user(String.t(), User.t()) ::
          {:ok, Collection.t()} | {:error, :not_found}
  def get_collection_for_user(id, %User{id: user_id}, opts \\ %{preloads: [:photos]}) do
    # For now, only allow access to owned collections
    # In the future, this will include collections the user is invited to
    case Collection
         |> where([c], c.id == ^id and c.owner_id == ^user_id)
         |> maybe_preload(opts[:preloads])
         |> Repo.one() do
      nil -> {:error, :not_found}
      collection -> {:ok, collection}
    end
  end

  @spec user_owns_collection?(User.t(), String.t()) ::
          {:ok, true} | {:error, :not_found | :forbidden}
  def user_owns_collection?(%User{id: user_id}, collection_id) do
    case get_collection(collection_id) do
      nil ->
        {:error, :not_found}

      %Collection{owner_id: ^user_id} ->
        {:ok, true}

      _collection ->
        {:error, :forbidden}
    end
  end

  def add_user(scope, %{collection_id: collection_id, user_id: user_id, inviter_id: inviter_id}) do
    if can_mutate_collection?(scope, collection_id) do
      %Member{}
      |> Member.changeset(%{
        user_id: user_id,
        collection_id: collection_id,
        inviter_id: inviter_id
      })
      |> Repo.insert()
    else
      {:error, :forbidden}
    end
  end

  def list_users(scope, %Collection{id: collection_id} = collection, opts \\ %{}) do
    if can_read_collection?(scope, collection) do
      User
      |> join(:inner, [u], m in Member, on: m.user_id == u.id)
      |> where([u, m], m.collection_id == ^collection_id)
      |> maybe_preload(opts[:preloads])
      |> Repo.all()
    else
      {:error, :forbidden}
    end
  end

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads) when is_list(preloads), do: preload(query, ^preloads)
  defp maybe_preload(query, preload) when is_atom(preload), do: preload(query, ^preload)

  def can_read_collection?(%P.Scope{current_user: nil}, _collection), do: false

  def can_read_collection?(%P.Scope{current_user: current_user}, collection) do
    if current_user.id == collection.owner_id do
      true
    else
      P.Repo.exists?(
        from m in Member,
          where: m.collection_id == ^collection.id and m.user_id == ^current_user.id
      )
    end
  end

  def can_mutate_collection?(%P.Scope{current_user: user}, collection)
      when is_binary(collection),
      do: user.id == P.Repo.get(Collection, collection).owner_id
end
