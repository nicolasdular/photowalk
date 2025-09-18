defmodule Thexstack.TaskManager do
  use Ash.Domain, extensions: [AshTypescript.Rpc]

  typescript_rpc do
    resource Thexstack.Schema.Todo do
      rpc_action(:list_todos, :read)
      rpc_action(:create_todo, :create)
    end
  end

  resources do
    resource Thexstack.Schema.Todo
  end
end
