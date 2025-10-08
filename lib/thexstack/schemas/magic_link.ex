defmodule Thexstack.MagicLink do
  use Ecto.Schema
  import Ecto.Changeset

  schema "magic_links" do
    field :token_hash, :binary
    field :email, :string
    field :expires_at, :utc_datetime_usec
    field :used_at, :utc_datetime_usec

    timestamps()
  end

  @doc false
  def changeset(magic_link, attrs) do
    magic_link
    |> cast(attrs, [:token_hash, :email, :expires_at, :used_at])
    |> validate_required([:token_hash, :email, :expires_at])
    |> unique_constraint(:token_hash)
  end
end
