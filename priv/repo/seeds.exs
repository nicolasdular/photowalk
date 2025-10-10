if Mix.env() == :dev do
  {:ok, user} =
    %P.User{email: "hello@nicolasdular.com"}
    |> P.Repo.insert()

  IO.puts("Seed user created: #{user.email}")
end
