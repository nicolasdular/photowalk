defmodule P.Factory do
  @moduledoc "Test data helpers for succinct fixtures."

  alias P.{Repo, Scope}
  alias P.User
  @upload_fixture Path.expand("fixtures/sample.jpg", __DIR__)

  def unique_email do
    "user-#{System.unique_integer([:positive])}@example.com"
  end

  def user_fixture(attrs \\ %{}) do
    attrs = attrs |> Enum.into(%{email: unique_email()})

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  def scope_fixture(attrs \\ %{}) do
    attrs = normalize_attrs(attrs)

    name = Map.get(attrs, :name, :test)
    current_user = Map.get(attrs, :current_user) || Map.get(attrs, :user)
    Scope.new(name: name, current_user: current_user)
  end

  def photo_fixture(attrs \\ %{}) do
    attrs = normalize_attrs(attrs)
    user = Map.get(attrs, :user) || user_fixture()
    upload = Map.get(attrs, :upload) || build_upload()

    {:ok, photo} = P.Photos.create_photo(user, upload)
    photo
  end

  def upload_fixture do
    build_upload()
  end

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)
  defp normalize_attrs(%{} = attrs), do: attrs

  defp build_upload do
    %Plug.Upload{
      path: @upload_fixture,
      filename: "sample.jpg",
      content_type: "image/jpeg"
    }
  end
end
