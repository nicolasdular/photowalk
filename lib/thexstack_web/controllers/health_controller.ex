defmodule ThexstackWeb.HealthController do
  use ThexstackWeb, :controller

  def up(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end

