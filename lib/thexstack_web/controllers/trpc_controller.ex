defmodule ThexstackWeb.RpcController do
  use ThexstackWeb, :controller

  def run(conn, params) do
    result = AshTypescript.Rpc.run_action(:thexstack, conn, params)
    json(conn, result)
  end

  def validate(conn, params) do
    result = AshTypescript.Rpc.validate_action(:thexstack, conn, params)
    json(conn, result)
  end
end
