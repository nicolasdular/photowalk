defmodule Thexstack.Repo do
  use Ecto.Repo,
    otp_app: :thexstack,
    adapter: Ecto.Adapters.Postgres
end
