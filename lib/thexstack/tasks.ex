defmodule Thexstack.Tasks do
  use Ash.Domain, extensions: [AshTypescript.Rpc]

  typescript_rpc do
    resource Thexstack.Tasks.Todo do
      rpc_action(:list_todos, :list)
      rpc_action(:create_todo, :create)
      rpc_action(:update_todo, :update)
    end
  end

  resources do
    resource Thexstack.Tasks.Todo
  end
end
