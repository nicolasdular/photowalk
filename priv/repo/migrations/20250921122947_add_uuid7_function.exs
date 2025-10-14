defmodule P.Repo.Migrations.AddUUID7Function do
  use Ecto.Migration

  def up do
    execute("""
    create or replace function uuid_generate_v7(
      ts timestamptz default null
    ) returns uuid
    as $$
      -- use random v4 uuid as starting point (which has the same variant we need)
      -- then overlay timestamp
      -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
    select encode(
      set_bit(
        set_bit(
          overlay(
            uuid_send(gen_random_uuid())
            placing substring(int8send(floor(extract(epoch from coalesce(ts, clock_timestamp())) * 1000)::bigint) from 3)
            from 1 for 6
          ),
          52, 1
        ),
        53, 1
      ),
      'hex')::uuid;
    $$ language sql volatile;
    """)
  end

  def down do
    execute("DROP FUNCTION IF EXISTS uuid_generate_v7")
  end
end
