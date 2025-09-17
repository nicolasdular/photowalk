defmodule ThexstackWeb.PageController do
  use ThexstackWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
