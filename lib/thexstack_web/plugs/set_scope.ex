defmodule ThexstackWeb.Plugs.SetScope do
  @moduledoc """
  Builds the request scope and assigns it to the connection.

  The scope is available as `conn.assigns.current_scope` and must be passed as
  the first argument to all domain modules.
  """

  import Plug.Conn

  alias Thexstack.Scope

  @behaviour Plug

  @impl Plug
  def init(opts) when is_atom(opts), do: %{name: opts}

  def init(opts) when is_list(opts) do
    name = Keyword.fetch!(opts, :name)
    metadata = Keyword.get(opts, :metadata)

    %{name: name, metadata: metadata}
  end

  @impl Plug
  def call(conn, %{name: name} = opts) do
    metadata = build_metadata(conn, Map.get(opts, :metadata))
    current_user = conn.assigns[:current_user]

    scope =
      conn.assigns
      |> Map.get(:current_scope)
      |> update_or_build_scope(name, current_user, metadata)

    assign(conn, :current_scope, scope)
  end

  defp update_or_build_scope(%Scope{} = scope, name, current_user, metadata) do
    scope
    |> Scope.with_name(name)
    |> Scope.put_current_user(current_user)
    |> Scope.merge_metadata(metadata)
  end

  defp update_or_build_scope(nil, name, current_user, metadata) do
    Scope.new(name: name, current_user: current_user, metadata: metadata)
  end

  defp build_metadata(conn, nil) do
    default_metadata(conn)
  end

  defp build_metadata(conn, fun) when is_function(fun, 1) do
    conn
    |> default_metadata()
    |> Map.merge(fun.(conn))
  end

  defp build_metadata(conn, %{} = extra) do
    conn
    |> default_metadata()
    |> Map.merge(extra)
  end

  defp build_metadata(conn, _invalid) do
    default_metadata(conn)
  end

  defp default_metadata(conn) do
    %{
      host: conn.host,
      path: conn.request_path,
      request_id: get_req_header(conn, "x-request-id") |> List.first()
    }
  end
end
