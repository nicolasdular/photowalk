defmodule P.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :citext, null: false
      add :confirmed_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
