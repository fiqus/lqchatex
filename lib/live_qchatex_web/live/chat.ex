defmodule LiveQchatexWeb.LiveChat.Chat do
  use Phoenix.LiveView
  require Logger
  alias LiveQchatex.Chats
  alias LiveQchatex.Models
  alias LiveQchatexWeb.ChatView
  alias LiveQchatexWeb.Router.Helpers, as: Routes

  def mount(%{sid: sid, path_params: %{"id" => id}}, socket) do
    try do
      if connected?(socket), do: Chats.subscribe()
      {:ok, socket |> fetch_chat!(id) |> fetch_user(sid) |> fetch()}
    rescue
      err ->
        Logger.error("Can't mount the chat #{inspect(err)}")

        {:stop,
         socket
         # @TODO Make this error to be displayed on home screen! (NOT WORKING)
         |> put_flash(:error, "The chat doesn't exist!")
         |> redirect(to: Routes.live_path(socket, LiveQchatexWeb.LiveChat.Home))}
    end
  end

  def render(assigns) do
    ChatView.render("chat.html", assigns)
  end

  def handle_info({[:chat | _action], _result} = info, socket) do
    IO.inspect(info, label: "[chat-view] HANDLE INFO CHAT")
    {:noreply, socket |> fetch()}
  end

  def handle_info({[:user | _action], _result} = info, socket) do
    IO.inspect(info, label: "[chat-view] HANDLE INFO USER")
    {:noreply, socket |> fetch()}
  end

  defp fetch_chat!(socket, id) do
    socket |> assign(chat: Chats.get_chat!(id))
  end

  defp fetch_user(socket, sid) do
    {:ok, %Models.User{} = user} = Chats.create_user(sid)
    socket |> assign(user: user)
  end

  defp fetch(socket) do
    socket
    |> assign(
      counters: %{
        chats: Chats.count_chats(),
        users: Chats.count_users()
      },
      error: "",
      info: "",
      success: ""
    )
  end
end
