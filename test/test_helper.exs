upload_cleanup_path = Path.expand("../priv/waffle/test/uploads", __DIR__)

ExUnit.configure(after_suite: [fn _ ->
  File.rm_rf(upload_cleanup_path)
end])

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(P.Repo, :manual)
