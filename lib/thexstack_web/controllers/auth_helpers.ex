defmodule ThexstackWeb.AuthHelpers do
  @moduledoc """
  Helper functions for authentication in controllers and LiveViews.
  """

  @doc """
  Gets the current user from the connection assigns.

  Returns the user struct or nil if not authenticated.
  """
  def get_current_user(conn_or_socket) do
    case conn_or_socket do
      %Plug.Conn{} = conn ->
        conn.assigns[:current_user]

      %Phoenix.LiveView.Socket{} = socket ->
        socket.assigns[:current_user]

      _ ->
        nil
    end
  end

  @doc """
  Checks if a user is authenticated.

  Returns true if current_user is present, false otherwise.
  """
  def authenticated?(conn_or_socket) do
    get_current_user(conn_or_socket) != nil
  end
end
