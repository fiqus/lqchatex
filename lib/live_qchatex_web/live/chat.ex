defmodule LiveQchatexWeb.LiveChat.Chat do
  use LiveQchatexWeb, :live_view

  @view_name "chat-room"

  def mount(%{sid: sid, path_params: %{"id" => id}}, socket) do
    setup_logger(socket, @view_name)

    try do
      socket = socket |> fetch_chat!(id) |> fetch_user(sid)
      if connected?(socket), do: Chats.track(socket.assigns.chat, socket.assigns.user)
      {:ok, socket |> maybe_clear_invite() |> fetch()}
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

  @impl Handlers
  def handle_chat_created(socket, _chat),
    do: socket |> update_counter(:chats, 1)

  @impl Handlers
  def handle_chat_updated(socket, chat),
    do: socket |> update_chat(chat)

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
        socket |> update_members()
    end
  end

  def handle_info({[:user, :typing, :end]} = info, socket) do
    Logger.debug("HANDLE USER TYPING END: #{inspect(info)}", ansi_color: :magenta)

    user = Chats.update_last_activity!(socket.assigns.user)
    Chats.update_member_typing(socket.assigns.chat, socket.assigns.user, false)
    {:noreply, socket |> assign(:user, user)}
  end

  def handle_info({[:message, :created], message} = info, socket) do
    Logger.debug("HANDLE MESSAGE CREATED: #{inspect(info)}", ansi_color: :magenta)

    {:noreply, socket |> update_messages(message)}
  end

  def handle_info(info, socket) do
    Logger.warn("UNHANDLED INFO: #{inspect(info)}")
    {:noreply, socket}
  end

  def handle_event("typing", _data, socket) do
    try do
      Chats.update_member_typing(socket.assigns.chat, socket.assigns.user, true)

      Map.get(socket.assigns, :typing_timer, nil) |> maybe_cancel_typing_timer()

      timer_ref =
        Process.send_after(
          self(),
          {[:user, :typing, :end]},
          Application.get_env(:live_qchatex, :timers)[:user_typing_timeout] * 1000
        )

      {:noreply, socket |> assign(:typing_timer, timer_ref)}
    rescue
      err ->
        Logger.error("Can't update typing status #{inspect(err)}")
        {:noreply, socket}
    end
  end

  def handle_event("message", %{"message" => data}, %{:assigns => assigns} = socket) do
    try do
      case get_message_type(data["text"]) do
        {:nickname, nick} ->
          socket |> maybe_update_nickname(nick)

        {:message, text} ->
          {:ok, message} = Chats.create_message(assigns.chat, assigns.user, text)
          {:noreply, socket |> update_messages(message)}

        _ ->
          {:noreply, socket}
      end
    rescue
      err ->
        Logger.error("Can't send the message #{inspect(err)}")
        response_error(socket, "Couldn't send the message!")
    end
  end

  def handle_event("update_nickname", %{"nick" => nick}, socket) do
    socket
    |> assign(click: nil)
    |> maybe_update_nickname(nick)
  end

  def handle_event("update_title", %{"title" => title}, socket) do
    socket
    |> assign(click: nil)
    |> maybe_update_title(title)
  end

  def handle_event("toggle_scope", _, socket) do
    socket |> maybe_toggle_scope()
  end

  def handle_event("click", data, socket) do
    {:noreply, socket |> assign(:click, data)}
  end

  def handle_event(event, data, socket) do
    Logger.warn("UNHANDLED EVENT '#{event}': #{inspect(data)}")
    {:noreply, socket}
  end

  defp fetch_chat!(socket, id) do
    socket |> assign(chat_id: id, chat: Chats.get_chat!(id))
  end

  defp fetch_user(socket, sid) do
    {:ok, %Models.User{} = user} = Chats.get_or_create_user(sid)
    socket |> assign(sid: sid, user: user)
  end

  defp fetch(%{:assigns => %{:chat => chat}} = socket) do
    socket
    |> update_members()
    |> update_invites()
    |> assign(
      messages: Chats.get_messages(chat),
      counters: %{
        chats: Chats.count_chats(),
        users: Chats.count_users()
      },
      error: "",
      info: "",
      success: ""
    )
  end

  defp set_counter(%{:assigns => %{:counters => counters}} = socket, key, amount) do
    socket |> assign(:counters, counters |> Map.put(key, amount))
  end

  defp update_counter(%{:assigns => %{:counters => counters}} = socket, key, amount) do
    socket |> set_counter(key, counters[key] + amount)
  end

  defp update_chat(%{:assigns => %{:chat => chat}} = socket, key, value) do
    {:ok, chat} = Chats.update_chat(chat, %{key => value})

    socket |> update_chat(chat)
  end

  defp update_chat(%{:assigns => %{:chat => chat}} = socket, %Models.Chat{} = updated) do
    if chat.id == updated.id,
      do: socket |> assign(chat: updated),
      else: socket
  end

  defp update_user(%{:assigns => %{:chat => chat, :user => user}} = socket, key, value) do
    {:ok, user} = Chats.update_user(user, %{key => value})

    socket
    |> assign(user: user)
    |> assign(chat: chat |> Chats.update_chat_member(user))
  end

  defp update_members(%{assigns: %{chat: chat}} = socket) do
    socket |> assign(members: chat |> Chats.list_chat_members())
  end

  defp update_invites(%{assigns: %{user: user}} = socket) do
    socket |> assign(invites: user |> Chats.list_chat_invites())
  end

  defp update_messages(%{:assigns => %{:messages => messages}} = socket, message) do
    socket |> assign(:messages, messages ++ [message])
  end

  defp update_nickname(%{:assigns => %{:user => user}} = socket, nick) do
    Logger.debug("Changed nickname to: #{inspect(nick)}")
    message = "Renamed from #{inspect(user.nickname)} to #{inspect(nick)}"

    handle_event(
      "message",
      %{"message" => %{"text" => message}},
      socket |> update_user(:nickname, nick)
    )
  end

  defp maybe_update_nickname(%{:assigns => %{:user => user}} = socket, nick) do
    nick = nick |> String.trim()

    if user.nickname != nick and nick |> String.length() > 0 do
      socket |> update_nickname(nick)
    else
      # socket |> response_error("The nickname is not valid!")
      {:noreply, socket}
    end
  end

  defp update_title(%{:assigns => %{:chat => chat}} = socket, title) do
    Logger.debug("Changed title to: #{inspect(title)}")
    message = "Changed chat title from #{inspect(chat.title)} to #{inspect(title)}"

    handle_event(
      "message",
      %{"message" => %{"text" => message}},
      socket |> update_chat(:title, title)
    )
  end

  defp maybe_update_title(%{:assigns => %{:chat => chat, :user => user}} = socket, title) do
    title = title |> String.trim()

    if chat.user_id == user.id && chat.title != title and title |> String.length() > 0 do
      socket |> update_title(title)
    else
      # socket |> response_error("The title is not valid!")
      {:noreply, socket}
    end
  end

  defp maybe_toggle_scope(%{:assigns => %{:chat => chat, :user => user}} = socket) do
    if chat.user_id == user.id do
      scope = if chat.private, do: "public", else: "private"
      Logger.debug("Changing chat scope to: #{scope}")

      {:noreply, socket |> update_chat(:private, scope == "private")}
    else
      {:noreply, socket}
    end
  end

  defp maybe_clear_invite(%{assigns: assigns} = socket) do
    Chats.topic(assigns.user)
    |> LiveQchatex.Presence.list_presences()
    |> Enum.find(&(&1.chat == assigns.chat.id))
    |> maybe_clear_invite(socket)
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

  defp maybe_cancel_typing_timer(nil), do: :ignore
  defp maybe_cancel_typing_timer(typing_timer), do: Process.cancel_timer(typing_timer)

  defp get_message_type(text) do
    cond do
      Regex.match?(~r/^\s*\/nick\s+(.*)/, text) ->
        [_, nick] = Regex.run(~r/\/nick\s+(.*)/, text)
        {:nickname, nick |> String.trim()}

      String.trim(text) != "" ->
        {:message, text}

      true ->
        {:ignore, text}
    end
  end

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
