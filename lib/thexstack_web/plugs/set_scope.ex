defmodule ThexstackWeb.Plugs.SetScope do
  import Plug.Conn

  alias Thexstack.{Repo, Scope, User}

  @behaviour Plug

  @impl Plug
  def init(opts) when is_atom(opts), do: %{name: opts}

  def init(opts) when is_list(opts), do: %{name: Keyword.fetch!(opts, :name)}

  @impl Plug
  def call(conn, %{name: name}) do
    {conn, current_user} = fetch_current_user(conn)

    scope =
      conn.assigns
      |> Map.get(:current_scope)
      |> update_or_build_scope(name, current_user)

    conn
    |> assign(:current_user, current_user)
    |> assign(:current_scope, scope)
  end

  defp fetch_current_user(conn) do
    case get_session(conn, :user_id) do
      nil ->
        {conn, nil}

      user_id ->
        case Repo.get(User, user_id) do
          %User{} = user ->
            {conn, user}

          nil ->
            conn = clear_session(conn)
            {conn, nil}
        end
    end
  end

  defp update_or_build_scope(%Scope{} = scope, name, current_user) do
    scope
    |> Scope.with_name(name)
    |> Scope.put_current_user(current_user)
  end

  defp update_or_build_scope(nil, name, current_user) do
    Scope.new(name: name, current_user: current_user)
  end
end
