defmodule P.Collections do
  import Ecto.Query

  alias P.{Collection, Member, Repo, User, Scope}

  @spec list_collections(Scope.t()) :: [Collection.t()]
  def list_collections(%Scope{current_user: %User{id: user_id}}, opts \\ %{}) do
    Collection
    |> join(:inner, [c], m in Member, on: m.collection_id == c.id)
    |> where([c, m], m.user_id == ^user_id)
    |> maybe_preload(opts[:preloads])
    |> Repo.all()
  end

  @spec create_collection(Scope.t(), map()) :: {:ok, Collection.t()} | {:error, Ecto.Changeset.t()}
  def create_collection(%Scope{current_user: user}, attrs) do
    Repo.transaction(fn ->
      with {:ok, collection} <-
             %Collection{}
             |> Collection.changeset(Map.put(attrs, "owner_id", user.id))
             |> Repo.insert(),
           {:ok, _member} <- insert_member(%{user_id: user.id, collection_id: collection.id}) do
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

  @spec get_collection(Scope.t(), String.t()) :: {:ok, Collection.t()} | {:error, :not_found}
  def get_collection(scope, id, opts \\ %{preloads: [:photos]}) do
    case Collection
         |> where([c], c.id == ^id)
         |> maybe_preload(opts[:preloads])
         |> Repo.one() do
      nil ->
        {:error, :not_found}

      collection ->
        case can_read_collection?(scope, collection) do
          true -> {:ok, collection}
          false -> {:error, :forbidden}
        end
    end
  end

  @spec user_owns_collection?(User.t(), String.t()) ::
          {:ok, true} | {:error, :not_found | :forbidden}
  def user_owns_collection?(%User{id: user_id}, collection_id) do
    case Repo.get(Collection, collection_id) do
      nil ->
        {:error, :not_found}

      %Collection{owner_id: ^user_id} ->
        {:ok, true}

      _collection ->
        {:error, :forbidden}
    end
  end

  def add_user(scope, %{collection_id: collection_id, email: email, inviter_id: inviter_id}) do
    case P.Accounts.get_user_by_email(scope, email) do
      nil ->
        {:error, :user_not_found}

      %User{id: user_id} ->
        add_user(scope, %{collection_id: collection_id, user_id: user_id, inviter_id: inviter_id})
    end
  end

  def add_user(scope, %{collection_id: collection_id, user_id: user_id, inviter_id: inviter_id}) do
    if can_mutate_collection?(scope, collection_id) do
      insert_member(%{user_id: user_id, collection_id: collection_id, inviter_id: inviter_id})
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
      when is_binary(collection) do
    case P.Repo.get(Collection, collection) do
      %Collection{owner_id: owner_id} -> user.id == owner_id
      nil -> false
    end
  end

  defp insert_member(params) do
    %Member{}
    |> Member.changeset(%{
      user_id: params[:user_id],
      collection_id: params[:collection_id],
      inviter_id: params[:inviter_id]
    })
    |> Repo.insert()
  end
end
