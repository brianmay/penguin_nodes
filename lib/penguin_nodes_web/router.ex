defmodule PenguinNodesWeb.Router do
  use PenguinNodesWeb, :router

  use Plugoid.RedirectURI,
    token_callback: &PenguinNodesWeb.TokenCallback.callback/5

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PenguinNodesWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  defmodule PlugoidConfig do
    def common do
      config = Application.get_env(:penguin_nodes, :oidc)

      [
        issuer: config.discovery_document_uri,
        client_id: config.client_id,
        scope: String.split(config.scope, " "),
        client_config: PenguinNodesWeb.ClientCallback
      ]
    end
  end

  pipeline :auth do
    plug Replug,
      plug: {Plugoid, on_unauthenticated: :pass},
      opts: {PlugoidConfig, :common}
  end

  pipeline :ensure_auth do
    plug Replug,
      plug: {Plugoid, on_unauthenticated: :auth},
      opts: {PlugoidConfig, :common}
  end

  pipeline :ensure_admin do
    plug PenguinNodesWeb.Plug.CheckAdmin
  end

  live_session :default, on_mount: PenguinNodesWeb.InitAssigns do
    scope "/", PenguinNodesWeb do
      pipe_through [:browser, :auth]
      get "/", PageController, :index
      post "/logout", PageController, :logout
    end

    scope "/", PenguinNodesWeb do
      pipe_through [:browser, :ensure_auth]
      get "/login", PageController, :login
      live "/aemo", Live.Aemo, :index
      live "/tesla", Live.Tesla, :index
    end
  end

  scope "/", PenguinNodesWeb do
    pipe_through [:browser, :auth, :ensure_admin]
    live_dashboard "/dashboard", metrics: PenguinNodesWeb.Telemetry
  end
end
