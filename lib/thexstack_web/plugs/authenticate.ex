defmodule ThexstackWeb.Plugs.Authenticate do
  @moduledoc """
  Plug to authenticate requests and load the current user.

  This plug checks the session for a user ID and loads the user from the database.
  It sets `conn.assigns.current_user` if a valid user is found, or nil otherwise.

  This plug does not require authentication - it only loads the user if present.
  Use `RequireAuth` plug to enforce authentication.
  """

  import Plug.Conn

  alias Thexstack.Accounts.User
  alias Thexstack.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      case Repo.get(User, user_id) do
        nil ->
          # User ID in session but user doesn't exist - clear session
          conn
          |> clear_session()
          |> assign(:current_user, nil)

        user ->
          assign(conn, :current_user, user)
      end
    else
      assign(conn, :current_user, nil)
    end
  end
end
