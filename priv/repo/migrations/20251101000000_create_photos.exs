defmodule P.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
      add :title, :string, null: false
      add :upload_key, :uuid, null: false
      add :image, :string, null: false
      add :source_filename, :string
      add :content_type, :string
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :collection_id, references(:collections, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:photos, [:upload_key])
    create index(:photos, [:user_id])
    create index(:photos, [:collection_id])
  end
end
