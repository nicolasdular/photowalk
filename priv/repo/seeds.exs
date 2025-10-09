# Create a user using Ash framework
{:ok, user} =
  %P.User{email: "hello@nicolasdular.com"}
  |> P.Repo.insert()

IO.puts("Seed user created: #{user.email}")
