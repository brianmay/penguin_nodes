defmodule PenguinNodesWeb.Plug.CheckAdmin do
  @moduledoc "Plugin to check if user is admin"
  import Plug.Conn

  use PenguinNodesWeb, :controller

  def init(_params) do
  end

  def call(%Plug.Conn{} = conn, _params) do
    user = PenguinNodesWeb.Auth.current_user(conn)

    if PenguinNodesWeb.Auth.user_is_admin?(user) do
      conn
    else
      conn
      |> put_flash(:danger, "You must be admin to access this.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
