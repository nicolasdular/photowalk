defmodule Thexstack.Accounts.Token do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:jti, :string, autogenerate: false}
  schema "tokens" do
    field :subject, :string
    field :expires_at, :utc_datetime
    field :purpose, :string
    field :extra_data, :map

    belongs_to :user, Thexstack.Accounts.User, define_field: false, foreign_key: :subject, references: :id, type: :string

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:jti, :subject, :expires_at, :purpose, :extra_data])
    |> validate_required([:jti, :subject, :expires_at, :purpose])
  end
end
