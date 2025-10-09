defmodule PWeb.HealthController do
  use PWeb, :controller

  def up(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
