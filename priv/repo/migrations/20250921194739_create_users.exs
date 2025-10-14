defmodule P.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
      add :name, :string, null: false
      add :email, :citext, null: false
      add :confirmed_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
