defmodule ThexstackWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug to require authentication for protected routes.

  This plug checks if a current user is present in the connection assigns.
  If no user is found, it returns a 401 Unauthorized JSON response.

  This plug should be used after the `Authenticate` plug, which loads the user.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(json: ThexstackWeb.ErrorJSON)
      |> render(:"401")
      |> halt()
    end
  end
end
