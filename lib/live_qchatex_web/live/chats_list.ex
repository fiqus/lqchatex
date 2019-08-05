defmodule LiveQchatexWeb.LiveChat.ChatsList do
  use Phoenix.LiveView
  require Logger
  alias LiveQchatex.Chats
  alias LiveQchatexWeb.ChatView

  def mount(_, socket) do
    if connected?(socket), do: [Chats.subscribe(), Chats.subscribe(:presence, :chats)]
    {:ok, socket |> fetch()}
  end

  def render(assigns) do
    ChatView.render("chats_list.html", assigns)
  end

  def handle_info({[:chat, :created], chat} = info, socket) do
    Logger.debug("[#{socket.id}][chats-list-view] HANDLE CHAT CREATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, if(chat.private != true, do: add_public_chat(socket, chat), else: socket)}
  end

  def handle_info({[:chat, :updated], chat} = info, socket) do
    Logger.debug("[#{socket.id}][chats-list-view] HANDLE CHAT UPDATED: #{inspect(info)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> update_public_chat(chat)}
  end

  def handle_info({[:chat, :cleared], _} = info, socket) do
    Logger.debug("[#{socket.id}][chats-list-view] HANDLE CHAT CLEARED: #{inspect(info)}",
      ansi_color: :magenta
    )

    # Reload all public chats again (should be improved)
    {:noreply, socket |> fetch()}
  end

  def handle_info(%{event: "presence_diff", topic: topic, payload: payload}, socket) do
    Logger.debug(
      "[#{socket.id}][chats-list-view] HANDLE PRESENCE DIFF FOR '#{topic}': #{inspect(payload)}",
      ansi_color: :magenta
    )

    {:noreply, socket |> handle_presence_payload(topic, payload)}
  end

  def handle_info(info, socket) do
    Logger.warn("[#{socket.id}][chats-list-view] UNHANDLED INFO: #{inspect(info)}")
    {:noreply, socket}
  end

  defp handle_presence_payload(socket, _topic, %{joins: joins, leaves: leaves}) do
    chats_ids = Enum.uniq(Map.keys(joins) ++ Map.keys(leaves))

    chats =
      socket.assigns.chats
      |> Enum.map(&if Enum.member?(chats_ids, &1.id), do: add_chat_members_count(&1), else: &1)

    socket |> fetch(chats)
  end

  defp fetch(socket) do
    socket |> fetch(Chats.get_public_chats() |> Enum.map(&add_chat_members_count/1))
  end

  defp fetch(socket, chats) do
    socket
    |> assign(
      counter: length(chats),
      chats: chats
    )
  end

  defp add_public_chat(socket, chat) do
    Logger.debug("[#{socket.id}][chats-list-view] Adding public chat: #{chat.title}")
    socket |> fetch([chat |> add_chat_members_count() | socket.assigns.chats])
  end

  defp update_public_chat(socket, chat) do
    idx = socket.assigns.chats |> Enum.find_index(&(&1.id == chat.id))

    case {chat.private, idx} do
      {true, nil} ->
        socket

      {true, _} ->
        Logger.debug("[#{socket.id}][chats-list-view] Removing private chat: #{chat.title}")
        socket |> fetch(socket.assigns.chats |> Enum.reject(&(&1.id == chat.id)))

      {false, nil} ->
        socket |> add_public_chat(chat)

      {false, _} ->
        Logger.debug("[#{socket.id}][chats-list-view] Updating public chat: #{chat.title}")

        socket
        |> fetch(
          socket.assigns.chats
          |> Enum.map(&if &1.id == chat.id, do: add_chat_members_count(chat), else: &1)
        )
    end
  end

  defp add_chat_members_count(chat), do: chat |> Map.put(:members, Chats.count_chat_members(chat))
end
