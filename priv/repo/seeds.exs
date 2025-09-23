# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Thexstack.Repo.insert!(%Thexstack.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

[
  %Thexstack.Tasks.Todo{completed: false, title: "Set up tests"},
  %Thexstack.Tasks.Todo{completed: false, title: "Set up Resend"},
  %Thexstack.Tasks.Todo{completed: false, title: "Set up Oban"},
  %Thexstack.Tasks.Todo{
    completed: false,
    title: "Set up deployment using Dokku on fat Hetzner ARM server"
  },
  %Thexstack.Tasks.Todo{completed: false, title: "Set up Polar.sh"},
  %Thexstack.Tasks.Todo{completed: false, title: "Set up telemetry/sentry"},
  %Thexstack.Tasks.Todo{completed: false, title: "Make lots of money"}
]
|> Enum.each(&Thexstack.Repo.insert!/1)
