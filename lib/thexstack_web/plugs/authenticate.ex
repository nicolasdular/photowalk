defmodule ThexstackWeb.Plugs.Authenticate do
  import Plug.Conn

  alias Thexstack.Accounts.User
  alias Thexstack.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      case Repo.get(User, user_id) do
        nil ->
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
