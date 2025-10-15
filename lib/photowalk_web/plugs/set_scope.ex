defmodule PWeb.Plugs.SetScope do
  import Plug.Conn

  alias P.{Repo, Scope, User}

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    {conn, current_user} = fetch_current_user(conn)

    scope =
      conn.assigns
      |> Map.get(:current_scope)
      |> update_or_build_scope(current_user)

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

  defp update_or_build_scope(%Scope{} = scope, current_user) do
    scope
    |> Scope.put_current_user(current_user)
  end

  defp update_or_build_scope(nil, current_user) do
    Scope.new(current_user: current_user)
  end
end
