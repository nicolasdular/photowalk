plugins =
  [Spark.Formatter, Phoenix.LiveView.HTMLFormatter]
  |> Enum.filter(&Code.ensure_loaded?/1)

[
  import_deps: [:ecto, :ecto_sql, :phoenix, :open_api_spex],
  subdirectories: ["priv/*/migrations"],
  plugins: plugins,
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
