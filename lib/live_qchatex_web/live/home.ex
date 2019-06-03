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

  def handle_info({[:chat, :created], _chat} = info, socket) do
    Logger.debug("[#{socket.id}][home-view] HANDLE CHAT CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_counter(:chats, 1)}
  end

  def handle_info({[:user, :created], _user} = info, socket) do
    Logger.debug("[#{socket.id}][home-view] HANDLE USER CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_counter(:users, 1)}
  end

  def handle_info(info, socket) do
    Logger.warn("[#{socket.id}][home-view] UNHANDLED INFO: #{inspect(info)}")
    {:noreply, socket}
  end

  def handle_event("start", %{"chat" => cdata, "user" => udata}, socket) do
    try do
      {:ok, chat} = Chats.create_chat(cdata)
      {:ok, _user} = Chats.update_user(socket.assigns.user, udata)
      redirect_to_chat(socket, chat)
    rescue
      err ->
        Logger.error("Can't create the chat #{inspect(err)}")
        response_error(socket, "Can't create the chat!")
    end
  end

  def handle_event("join", %{"chat" => cdata, "user" => udata}, socket) do
    try do
      chat = Chats.get_chat!(cdata["id"])
      {:ok, _user} = Chats.update_user(socket.assigns.user, udata)
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
    {:ok, %Models.User{} = user} = Chats.get_or_create_user(sid)
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

  defp update_counter(%{:assigns => %{:counters => counters}} = socket, key, amount) do
    socket |> assign(:counters, counters |> Map.put(key, counters[key] + amount))
  end

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
