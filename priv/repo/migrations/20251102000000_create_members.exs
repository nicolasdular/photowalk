defmodule P.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      add :collection_id, references(:collections, type: :uuid, on_delete: :delete_all),
        null: false

      add :inviter_id, references(:users, type: :uuid, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:members, [:user_id, :collection_id])
    create index(:members, [:collection_id])
    create index(:members, [:inviter_id])
  end
end
