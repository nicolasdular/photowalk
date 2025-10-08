defmodule ThexstackWeb.Plugs.RequireAuth do
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
