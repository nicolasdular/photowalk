defmodule PWeb.PageController do
  use PWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
