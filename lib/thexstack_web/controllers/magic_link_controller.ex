defmodule ThexstackWeb.MagicLinkController do
  use ThexstackWeb, :controller

  alias Thexstack.Accounts.MagicLink

  def magic_link(conn, %{"token" => token}) do
    case MagicLink.verify_magic_link(token) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Successfully signed in!")
        |> redirect(to: "/")

      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid or expired magic link")
        |> redirect(to: "/")
    end
  end
end
