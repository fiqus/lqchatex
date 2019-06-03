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

  def handle_info({[:chat, :members_updated], members} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE MEMBERS UPDATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    chat = socket.assigns.chat |> Map.put(:members, members)
    {:noreply, socket |> assign(:members, parse_members(chat))}
  end

  def handle_info({[:user, :created], _user} = info, socket) do
    Logger.debug("[#{socket.id}][chat-view] HANDLE USER CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_counter(:users, 1)}
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

  def handle_event("message", %{"message" => data}, socket) do
    try do
      assigns = socket.assigns
      {:ok, message} = Chats.create_room_message(assigns.chat.id, assigns.user, data["text"])
      {:noreply, socket |> update_messages(message)}
    rescue
      err ->
        Logger.error("Can't send the message #{inspect(err)}")
        response_error(socket, "Couldn't send the message!")
    end
  end

  defp fetch_chat!(socket, id) do
    socket |> assign(chat: Chats.get_chat!(id))
  end

  defp fetch_user(socket, sid) do
    {:ok, %Models.User{} = user} = Chats.get_or_create_user(sid)

    socket
    |> assign(user: user)
    |> assign(chat: socket.assigns.chat |> Chats.add_chat_member(user))
  end

  defp fetch(socket) do
    chat = socket.assigns.chat

    socket
    |> assign(
      members: parse_members(chat),
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

  defp update_counter(%{:assigns => %{:counters => counters}} = socket, key, amount) do
    socket |> assign(:counters, counters |> Map.put(key, counters[key] + amount))
  end

  defp update_messages(%{:assigns => %{:messages => messages}} = socket, message) do
    socket |> assign(:messages, messages ++ [message])
  end

  defp parse_members(%Models.Chat{} = chat, %Models.User{} = user \\ %Models.User{}) do
    chat.members
    |> Enum.map(fn {member_id, member} ->
      member |> Map.put(:typing, is_member_typing?(member_id, user))
    end)
  end

  defp is_member_typing?(member_id, %{:id => user_id}), do: user_id != nil && member_id == user_id

  defp response_error(socket, error), do: {:noreply, assign(socket, error: error)}
end
