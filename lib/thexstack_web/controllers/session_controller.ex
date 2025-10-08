defmodule ThexstackWeb.SessionController do
  use ThexstackWeb, :controller

  alias Thexstack.Accounts

  def magic_link(conn, %{"token" => token}) do
    case Accounts.verify_magic_link(token) do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, user.id)
        |> redirect(to: "/")

      {:error, :invalid} ->
        conn
        |> redirect(to: "/signup?error=invalid_token")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_status(:ok)
    |> json(%{success: true})
  end
end
