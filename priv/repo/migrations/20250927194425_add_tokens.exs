defmodule Thexstack.Repo.Migrations.AddTokens do
  use Ecto.Migration

  def change do
    create table(:tokens, primary_key: false) do
      add :jti, :string, null: false, primary_key: true
      add :subject, :string, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :purpose, :string, null: false
      add :extra_data, :map

      timestamps()
    end
  end
end
