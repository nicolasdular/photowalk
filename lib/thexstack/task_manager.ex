defmodule Thexstack.TaskManager do
  use Ash.Domain, extensions: [AshTypescript.Rpc]

  typescript_rpc do
    resource Thexstack.Schema.Todo do
      rpc_action(:list_todos, :read)
      rpc_action(:create_todo, :create)
      rpc_action(:update_todo, :update)
    end
  end

  resources do
    resource Thexstack.Schema.Todo
  end
end
