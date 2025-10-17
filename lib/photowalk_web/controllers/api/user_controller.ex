defmodule PWeb.UserController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PWeb.API.Resources.User, as: UserResource
  alias PWeb.Api.Docs.Response

  tags(["user"])

  operation(:me, responses: [ok: Response.data(UserResource.schema(), "SignedInUserResponse")])

  def me(conn, _params) do
    json(conn, %{data: UserResource.serialize(current_user(conn))})
  end
end
