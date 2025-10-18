defmodule PWeb.ControllerHelpers do
  @moduledoc """
  Convenience helpers available to all controllers.
  """

  alias Plug.Conn

  @spec current_user(Conn.t()) :: any()
  def current_user(%Conn{} = conn), do: conn.assigns[:current_user]

  @spec scope(Conn.t()) :: any()
  def scope(%Conn{} = conn), do: conn.assigns[:current_scope]

  def present(conn, module, data, opts \\ []) do
    PWeb.API.Presenter.present(module, data, Keyword.put(opts, :current_user, current_user(conn)))
  end
end
