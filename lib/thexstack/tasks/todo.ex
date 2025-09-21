defmodule Thexstack.Tasks.Todo do
  use Ash.Resource, domain: Thexstack.Tasks, data_layer: AshPostgres.DataLayer

  postgres do
    table "todos"
    repo Thexstack.Repo
  end

  actions do
    defaults [:read]

    read :list do
      pagination do
        required? true
        keyset? true
        max_page_size 100
      end
    end

    create :create do
      accept [:title, :completed]
    end

    update :update do
      accept [:completed]
    end
  end

  attributes do
    integer_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :completed, :boolean, default: false, public?: true
  end
end
