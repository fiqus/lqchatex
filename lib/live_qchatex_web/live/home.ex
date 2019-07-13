defmodule LiveQchatexWeb.LiveChat.Home do
  use Phoenix.LiveView
  require Logger
  alias LiveQchatex.Chats
  alias LiveQchatex.Models
  alias LiveQchatexWeb.ChatView
  alias LiveQchatexWeb.Router.Helpers, as: Routes

  def mount(%{sid: sid}, socket) do
    try do
      socket = socket |> fetch_user(sid)
      if connected?(socket), do: Chats.track(socket.assigns.user)
      {:ok, socket |> fetch()}
    rescue
      err ->
        Logger.error("Can't mount the home view #{inspect(err)}")

        {:stop,
         socket
         # @TODO Make this error to be displayed on home screen! (NOT WORKING)
         |> put_flash(:error, "Sorry, an error was just happened!")}
    end
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

  def handle_info({[:chat, :cleared], counter} = info, socket) do
    Logger.debug("[#{socket.id}][home-view] HANDLE CHAT CLEARED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> set_counter(:chats, counter)}
  end

  def handle_info({[:user, :created], _user} = info, socket) do
    Logger.debug("[#{socket.id}][home-view] HANDLE USER CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_counter(:users, 1)}
  end

  def handle_info({[:user, :cleared], counter} = info, socket) do
    Logger.debug("[#{socket.id}][home-view] HANDLE USER CLEARED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> set_counter(:users, counter)}
  end

  def handle_info({:hearthbeat, _, _} = info, socket) do
    Logger.debug("[#{socket.id}][home-view] HANDLE HEARTHBEAT: #{inspect(info)}",
      ansi_color: :magenta
    )

    Chats.handle_hearthbeat(info, socket)
  end

  def handle_info(info, socket) do
    Logger.warn("[#{socket.id}][home-view] UNHANDLED INFO: #{inspect(info)}")
    {:noreply, socket}
  end

  def handle_event("start", %{"chat" => cdata, "user" => udata}, socket) do
    try do
      {:ok, user} = Chats.update_user(socket.assigns.user, udata)
      {:ok, chat} = Chats.create_chat(user, cdata)
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
     |> live_redirect(to: Routes.live_path(socket, LiveQchatexWeb.LiveChat.Chat, chat.id))}
  end

  defp fetch_user(socket, sid) do
    {:ok, %Models.User{} = user} = Chats.get_or_create_user(sid)
    socket |> assign(sid: sid, user: user)
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

  defp set_counter(%{:assigns => %{:counters => counters}} = socket, key, amount) do
    socket |> assign(:counters, counters |> Map.put(key, amount))
  end

  defp update_counter(%{:assigns => %{:counters => counters}} = socket, key, amount) do
    socket |> set_counter(key, counters[key] + amount)
  end

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
