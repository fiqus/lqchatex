defmodule LiveQchatexWeb.LiveChat.Home do
  use LiveQchatexWeb, :live_view

  @view_name "home"

  def mount(%{sid: sid}, socket) do
    setup_logger(socket, @view_name)

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

  @impl Handlers
  def handle_chat_created(socket, _chat),
    do: socket |> update_counter(:chats, 1)

  @impl Handlers
  def handle_chat_cleared(socket, counter),
    do: socket |> set_counter(:chats, counter)

  @impl Handlers
  def handle_user_created(socket, _user),
    do: socket |> update_counter(:users, 1)

  @impl Handlers
  def handle_user_cleared(socket, counter),
    do: socket |> set_counter(:users, counter)

  @impl Handlers
  def handle_presence_payload(socket, topic, payload) do
    cond do
      topic == Chats.topic(:presence, :chats) ->
        socket |> maybe_clear_invite(payload) |> update_invites()

      topic == Chats.topic(socket.assigns.user) ->
        socket |> update_invites()

      true ->
        socket
    end
  end

  def handle_info(info, socket) do
    Logger.warn("UNHANDLED INFO: #{inspect(info)}")
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

  defp redirect_to_chat(socket, chat) do
    {:noreply,
     socket
     |> live_redirect(to: Routes.live_path(socket, LiveQchatexWeb.LiveChat.Chat, chat.id))}
  end

  defp fetch_user(socket, sid) do
    {:ok, %Models.User{} = user} = Chats.get_or_create_user(sid)
    socket |> assign(sid: sid, user: user)
  end

  defp fetch(socket) do
    socket
    |> update_invites()
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

  defp update_invites(%{assigns: %{user: user}} = socket) do
    socket |> assign(invites: user |> Chats.list_chat_invites())
  end

  defp maybe_clear_invite(nil, socket), do: socket

  defp maybe_clear_invite(invite, %{assigns: assigns} = socket) do
    Chats.private_chat_clear(assigns.user, invite.key)
    socket
  end

  defp maybe_clear_invite(%{assigns: assigns} = socket, %{leaves: leaves}) do
    leaves
    |> Enum.each(fn {chat_id, %{metas: [%{user: user_id}]}} ->
      Chats.topic(assigns.user)
      |> LiveQchatex.Presence.list_presences()
      |> Enum.find(&(&1.chat == chat_id and &1.key == user_id))
      |> maybe_clear_invite(socket)
    end)

    socket
  end

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
