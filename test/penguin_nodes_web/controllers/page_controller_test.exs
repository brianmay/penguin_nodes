defmodule PenguinNodesWeb.PageControllerTest do
  use PenguinNodesWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to PenguinNodes!"
  end
end
