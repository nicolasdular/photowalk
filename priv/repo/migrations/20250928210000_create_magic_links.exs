defmodule P.Repo.Migrations.CreateMagicLinks do
  use Ecto.Migration

  def change do
    create table(:magic_links, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
      add :token_hash, :binary, null: false
      add :email, :citext, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :used_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:magic_links, [:token_hash])
    create index(:magic_links, [:email])
    create index(:magic_links, [:expires_at])
  end
end
