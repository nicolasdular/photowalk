defmodule ThexstackWeb.TestHelpers do
  @moduledoc "Shared helpers for web connection tests."

  import Plug.Conn

  alias Phoenix.ConnTest
  alias Thexstack.Accounts.User

  @doc """
  Ensures the connection carries standard JSON API headers.
  """
  @spec json_conn(Plug.Conn.t()) :: Plug.Conn.t()
  def json_conn(%Plug.Conn{} = conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("content-type", "application/json")
  end

  @doc """
  Logs in the given user by priming the test session.
  """
  @spec log_in_user(Plug.Conn.t(), User.t()) :: Plug.Conn.t()
  def log_in_user(%Plug.Conn{} = conn, %User{id: id}) do
    conn
    |> ConnTest.init_test_session(%{})
    |> put_session(:user_id, id)
  end

  @doc """
  Prepares a connection authenticated as the user with JSON headers applied.
  """
  @spec auth_json_conn(Plug.Conn.t(), User.t()) :: Plug.Conn.t()
  def auth_json_conn(conn, user) do
    conn
    |> log_in_user(user)
    |> json_conn()
  end
end
