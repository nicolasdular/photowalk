defmodule P.Repo do
  use Ecto.Repo,
    otp_app: :photowalk,
    adapter: Ecto.Adapters.Postgres
end
