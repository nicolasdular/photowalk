[
  import_deps: [
    :ecto,
    :ecto_sql,
    :phoenix
  ],
  import_deps: [:open_api_spex],
  subdirectories: ["priv/*/migrations"],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
