defmodule PWeb.ControllerHelpers do
  @moduledoc """
  Convenience helpers available to all controllers.
  """

  alias Plug.Conn

  @spec current_user(Conn.t()) :: any()
  def current_user(%Conn{} = conn), do: conn.assigns[:current_user]

  @spec scope(Conn.t()) :: any()
  def scope(%Conn{} = conn), do: conn.assigns[:current_scope]
end
