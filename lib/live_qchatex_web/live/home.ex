defmodule LiveQchatexWeb.LiveChat.Home do
  use Phoenix.LiveView
  require Logger
  alias LiveQchatex.Chats
  alias LiveQchatex.Models
  alias LiveQchatexWeb.ChatView
  alias LiveQchatexWeb.Router.Helpers, as: Routes

  def mount(%{sid: sid}, socket) do
    if connected?(socket), do: Chats.subscribe()
    {:ok, socket |> fetch_user(sid) |> fetch()}
  end

  def render(assigns) do
    ChatView.render("home.html", assigns)
  end

  def handle_info({[:chat | _action], _result} = info, socket) do
    IO.inspect(info, label: "[home-view] HANDLE INFO CHAT")
    {:noreply, socket |> fetch()}
  end

  def handle_info({[:user | _action], _result} = info, socket) do
    IO.inspect(info, label: "[home-view] HANDLE INFO USER")
    {:noreply, socket |> fetch()}
  end

  def handle_event("start", %{"chat" => data}, socket) do
    try do
      {:ok, chat} = Chats.create_chat(data)
      redirect_to_chat(socket, chat)
    rescue
      err ->
        Logger.error("Can't create the chat #{inspect(err)}")
        response_error(socket, "Can't create the chat!")
    end
  end

  def handle_event("join", %{"chat" => data}, socket) do
    try do
      chat = Chats.get_chat!(data["id"])
      redirect_to_chat(socket, chat)
    rescue
      err ->
        Logger.debug("Can't join the chat #{inspect(err)}")
        response_error(socket, "The chat doesn't exist!")
    end
  end

  defp redirect_to_chat(socket, chat) do
    {:stop,
     socket
     |> redirect(to: Routes.live_path(socket, LiveQchatexWeb.LiveChat.Chat, chat.id))}
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
      error: ""
    )
  end

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
