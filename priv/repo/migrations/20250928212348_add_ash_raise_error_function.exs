defmodule Thexstack.Repo.Migrations.AddAshRaiseErrorFunction do
  @moduledoc """
  Creates the ash_raise_error function required by Ash authorization policies.

  This function is normally created automatically when "ash-functions" is included
  in the repo's installed_extensions and migrations are generated, but sometimes
  needs to be created manually if not generated during initial setup.

  For new projects, ensure "ash-functions" is in installed_extensions before
  generating your first migrations.
  """
  use Ecto.Migration

  def up do
    # Create the ash_raise_error function that Ash uses for authorization policies
    execute """
    CREATE OR REPLACE FUNCTION ash_raise_error(error_json jsonb)
    RETURNS boolean AS $$
    BEGIN
      RAISE EXCEPTION 'Ash Error: %', error_json::text;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create the polymorphic version that returns any compatible type
    execute """
    CREATE OR REPLACE FUNCTION ash_raise_error(error_json jsonb, type_signal ANYCOMPATIBLE)
    RETURNS ANYCOMPATIBLE AS $$
    BEGIN
      RAISE EXCEPTION 'Ash Error: %', error_json::text;
    END;
    $$ LANGUAGE plpgsql;
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS ash_raise_error(jsonb, ANYCOMPATIBLE);"
    execute "DROP FUNCTION IF EXISTS ash_raise_error(jsonb);"
  end
end
