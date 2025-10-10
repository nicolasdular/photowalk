defmodule P.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :title, :string, null: false
      add :upload_key, :uuid, null: false
      add :image, :string, null: false
      add :source_filename, :string
      add :content_type, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:photos, [:upload_key])
    create index(:photos, [:user_id])
  end
end
