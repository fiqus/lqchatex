defmodule LiveQchatexWeb.LiveChat.Chat do
  use Phoenix.LiveView
  require Logger
  alias LiveQchatex.Chats
  alias LiveQchatex.Models
  alias LiveQchatexWeb.ChatView
  alias LiveQchatexWeb.Router.Helpers, as: Routes

  def mount(%{sid: sid, path_params: %{"id" => id}}, socket) do
    try do
      socket = socket |> fetch_chat!(id)

      if connected?(socket) do
        Chats.subscribe()
        Chats.subscribe(socket.assigns.chat)
      end

      {:ok, socket |> fetch_user(sid) |> fetch()}
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

  def handle_info({[:chat, :created], _chat} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE CHAT CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_counter(:chats, 1)}
  end

  def handle_info({[:chat, :cleared], counter} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE CHAT CLEARED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> set_counter(:chats, counter)}
  end

  def handle_info({[:chat, :members_updated], members} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE MEMBERS UPDATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    chat = socket.assigns.chat |> Map.put(:members, members)
    {:noreply, socket |> assign(chat: chat, members: parse_members(members))}
  end

  def handle_info({[:user, :created], _user} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE USER CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_counter(:users, 1)}
  end

  def handle_info({[:user, :cleared], counter} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE USER CLEARED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> set_counter(:users, counter)}
  end

  def handle_info({[:user, :typing, :end]} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE USER TYPING end: #{inspect(info)}",
      ansi_color: :magenta
    )

    %{:chat => %{:id => chat_id}, :user => %{:id => user_id} = user} = socket.assigns
    {:ok, _} = Chats.update_last_activity(user)
    :ok = Chats.broadcast_user_typing(chat_id, user_id, false)
    {:noreply, socket}
  end

  def handle_info({[:user, :typing, is_typing], user_id} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE USER TYPING #{is_typing}: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_typing(user_id, is_typing)}
  end

  def handle_info({[:message, :created], message} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE MESSAGE CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_messages(message)}
  end

  def handle_info(info, socket) do
    Logger.warn("[#{socket.id}][chat-view] UNHANDLED INFO: #{inspect(info)}")
    {:noreply, socket}
  end

  def handle_event("message", %{"message" => data}, %{:assigns => assigns} = socket) do
    try do
      case get_message_type(data["text"]) do
        {:nickname, nick} ->
          socket |> maybe_update_nickname(nick)

        {:message, text} ->
          {:ok, message} = Chats.create_room_message(assigns.chat, assigns.user, text)
          {:noreply, socket |> update_messages(message)}
      end
    rescue
      err ->
        Logger.error("Can't send the message #{inspect(err)}")
        response_error(socket, "Couldn't send the message!")
    end
  end

  def handle_event("typing", _data, socket) do
    try do
      %{:chat => %{:id => chat_id}, :user => %{:id => user_id}} = socket.assigns
      :ok = Chats.broadcast_user_typing(chat_id, user_id, true)

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

  def handle_event("update_nickname", %{"nick" => nick}, socket) do
    socket
    |> assign(click: nil)
    |> maybe_update_nickname(nick)
  end

  def handle_event("click", data, socket) do
    {:noreply, socket |> assign(:click, data)}
  end

  def handle_event(event, data, socket) do
    Logger.warn("[#{socket.id}][chat-view] UNHANDLED EVENT '#{event}': #{inspect(data)}")
    {:noreply, socket}
  end

  defp maybe_cancel_typing_timer(nil), do: :ignore
  defp maybe_cancel_typing_timer(typing_timer), do: Process.cancel_timer(typing_timer)

  defp fetch_chat!(socket, id) do
    socket |> assign(chat: Chats.get_chat!(id))
  end

  defp fetch_user(%{:assigns => %{:chat => chat}} = socket, sid) do
    {:ok, %Models.User{} = user} = Chats.get_or_create_user(sid)

    socket
    |> assign(user: user)
    |> assign(chat: chat |> Chats.update_chat_member(user))
  end

  defp fetch(%{:assigns => %{:chat => chat}} = socket) do
    socket
    |> assign(
      members: parse_members(chat.members),
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

  defp update_user(%{:assigns => %{:chat => chat, :user => user}} = socket, key, value) do
    {:ok, user} = Chats.update_user(user, %{key => value})

    socket
    |> assign(user: user)
    |> assign(chat: chat |> Chats.update_chat_member(user))
  end

  defp update_messages(%{:assigns => %{:messages => messages}} = socket, message) do
    socket |> assign(:messages, messages ++ [message])
  end

  defp update_typing(%{:assigns => %{:members => members}} = socket, user_id, is_typing) do
    socket |> assign(:members, parse_members(members, user_id, is_typing))
  end

  defp update_nickname(%{:assigns => %{:user => user}} = socket, nick) do
    Logger.debug("[#{socket.id}][chat-view] Changed nickname to: #{inspect(nick)}")
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

  defp get_message_type(text) do
    cond do
      Regex.match?(~r/^\s*\/nick\s+(.*)/, text) ->
        [_, nick] = Regex.run(~r/\/nick\s+(.*)/, text)
        {:nickname, nick |> String.trim()}

      true ->
        {:message, text}
    end
  end

  defp parse_members(members, user_id \\ nil, is_typing \\ false) do
    members
    |> Enum.map(&update_member_field(&1, user_id, :typing, is_typing))
  end

  defp update_member_field({member_id, member}, user_id, key, value),
    do:
      member
      |> Map.put(
        key,
        if(user_id == nil || user_id == member_id,
          do: value,
          else: Map.get(member, key, value)
        )
      )

  defp update_member_field(%{:id => id} = member, user_id, key, value),
    do: update_member_field({id, member}, user_id, key, value)

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
