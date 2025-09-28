defmodule Thexstack.Repo do
  use AshPostgres.Repo,
    otp_app: :thexstack

  @impl true
  def installed_extensions do
    # Add extensions here, and the migration generator will install them.
    #
    # "ash-functions" - Not a real PostgreSQL extension, but tells Ash to create
    # required functions like ash_raise_error() during migration generation.
    # This function is needed for authorization policies.
    #
    # "citext" - PostgreSQL extension for case-insensitive text fields
    ["ash-functions", "citext"]
  end

  # Don't open unnecessary transactions
  # will default to `false` in 4.0
  @impl true
  def prefer_transaction? do
    false
  end

  @impl true
  def min_pg_version do
    %Version{major: 17, minor: 5, patch: 0}
  end
end
