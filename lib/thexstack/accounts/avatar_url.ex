defmodule Thexstack.Accounts.AvatarUrl do
  use Ash.Resource.Calculation

  @impl true
  # A callback to tell Ash what keys must be loaded/selected when running this calculation
  # you can include related data here, but be sure to include the attributes you need from said related data
  # i.e `posts: [:title, :body]`.
  def load(_query, opts, _context) do
    opts[:email]
  end

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      email = to_string(record.email)
      hash = :crypto.hash(:md5, email) |> Base.encode16(case: :lower)
      "https://gravatar.com/avatar/" <> hash
    end)
  end
end
