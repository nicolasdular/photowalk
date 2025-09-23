defmodule ThexstackWeb.SessionController do
  use ThexstackWeb, :controller

  # Signs the user out by clearing the session and renewing it.
  # If you later want to revoke stored tokens, you can extend this action
  # to call your Token resource to revoke tokens for the current subject.
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
