# Create a user using Ash framework
{:ok, user} =
  %Thexstack.User{email: "hello@nicolasdular.com"}
  |> Thexstack.Repo.insert()

[
  %Thexstack.Todo{completed: false, title: "Set up tests", user_id: user.id},
  %Thexstack.Todo{completed: false, title: "Set up Resend", user_id: user.id},
  %Thexstack.Todo{completed: false, title: "Set up Oban", user_id: user.id},
  %Thexstack.Todo{
    completed: false,
    title: "Set up deployment using Dokku on fat Hetzner ARM server",
    user_id: user.id
  },
  %Thexstack.Todo{completed: false, title: "Set up Polar.sh", user_id: user.id},
  %Thexstack.Todo{completed: false, title: "Set up telemetry/sentry", user_id: user.id},
  %Thexstack.Todo{completed: false, title: "Make lots of money", user_id: user.id}
]
|> Enum.each(&Thexstack.Repo.insert!/1)
