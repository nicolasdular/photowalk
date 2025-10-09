defmodule P.Repo.Migrations.AddTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string, null: false
      add :completed, :boolean, default: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:todos, [:user_id])
  end
end
