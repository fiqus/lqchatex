defmodule LiveQchatexWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LiveQchatexWeb, :controller
      use LiveQchatexWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: LiveQchatexWeb

      import Plug.Conn
      import LiveQchatexWeb.Gettext
      import Phoenix.LiveView.Controller, only: [live_render: 3]
      alias LiveQchatexWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/live_qchatex_web/templates",
        namespace: LiveQchatexWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]
      import Phoenix.LiveView, only: [live_render: 2, live_render: 3, live_link: 1, live_link: 2]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import LiveQchatexWeb.ErrorHelpers
      import LiveQchatexWeb.Gettext
      alias LiveQchatexWeb.Router.Helpers, as: Routes
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      require Logger

      import LiveQchatexWeb.ErrorHelpers
      import LiveQchatexWeb.Gettext

      use LiveQchatexWeb.LiveChat.Handlers

      alias LiveQchatex.Chats
      alias LiveQchatex.Models
      alias LiveQchatexWeb.ChatView
      alias LiveQchatexWeb.LiveChat.Handlers
      alias LiveQchatexWeb.Router.Helpers, as: Routes

      defp setup_logger(socket, view),
        do: Logger.metadata(socket_id: "[#{socket.id}]", view: "[#{view}]")
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import LiveQchatexWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
