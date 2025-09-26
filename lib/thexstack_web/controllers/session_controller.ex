defmodule ThexstackWeb.SessionController do
  use ThexstackWeb, :controller

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_status(:ok)
    |> json(%{success: true})
  end
end
