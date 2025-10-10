defmodule PWeb.ErrorJSONTest do
  use PWeb.ConnCase, async: true

  test "renders 404" do
    assert PWeb.ErrorJSON.render("404.json", %{}) == %{error: "Not found"}
  end

  test "renders 500" do
    assert PWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
