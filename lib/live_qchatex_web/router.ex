defmodule LiveQchatexWeb.Router do
  use LiveQchatexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :put_layout, {LiveQchatexWeb.LayoutView, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LiveQchatexWeb.Plug.SessionSetup
  end

  scope "/", LiveQchatexWeb do
    pipe_through :browser

    live "/", LiveChat.Home, session: [:sid]
    live "/chat/:id", LiveChat.Chat, session: [:sid, :path_params]
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveQchatexWeb do
  #   pipe_through :api
  # end
end
