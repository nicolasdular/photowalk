defmodule P.Repo.Migrations.CreatePhotoLikes do
  use Ecto.Migration

  def change do
    create table(:photo_likes, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :photo_id, references(:photos, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:photo_likes, [:photo_id, :user_id])
  end
end
