defmodule PenguinNodesWeb.PageController do
  use PenguinNodesWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html", active: "home")
  end

  @spec logout(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def logout(conn, _params) do
    user = PenguinNodesWeb.Auth.current_user(conn)

    if user != nil do
      sub = user["sub"]
      PenguinNodesWeb.Endpoint.broadcast("users_socket:#{sub}", "disconnect", %{})
    end

    conn
    |> Plugoid.logout()
    |> put_session(:claims, nil)
    |> put_flash(:danger, "You are now logged out.")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  @spec login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login(conn, _params) do
    redirect(conn, to: Routes.page_path(conn, :index))
  end
end
