defmodule Thexstack.Tasks.Todo do
  use Ash.Resource,
    domain: Thexstack.Tasks,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

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
      change relate_actor(:user)
    end

    update :update do
      accept [:completed]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action(:create) do
      authorize_if relating_to_actor(:user)
    end

    policy action(:update) do
      authorize_if expr(user_id == ^actor(:id))
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

  relationships do
    belongs_to :user, Thexstack.Accounts.User do
      attribute_type :integer
      allow_nil? false
    end
  end
end
