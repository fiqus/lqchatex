defmodule LiveQchatexWeb.LiveChat.ChatsList do
  use LiveQchatexWeb, :live_view

  @behaviour Handlers
  @view_name "chat-list"

  def mount(_, socket) do
    setup_logger(socket, @view_name)
    if connected?(socket), do: [Chats.subscribe(), Chats.subscribe(:presence, :chats)]
    {:ok, socket |> fetch()}
  end

  def render(assigns) do
    ChatView.render("chats_list.html", assigns)
  end

  @impl Handlers
  def handle_chat_created(socket, chat),
    do: if(chat.private != true, do: add_public_chat(socket, chat), else: socket)

  @impl Handlers
  def handle_chat_updated(socket, chat),
    do: socket |> update_public_chat(chat)

  @impl Handlers
  def handle_chat_cleared(socket, _counter),
    # Reload all public chats again (should be improved)
    do: socket |> fetch()

  @impl Handlers
  def handle_presence_payload(socket, _topic, %{joins: joins, leaves: leaves}) do
    chats_ids = Enum.uniq(Map.keys(joins) ++ Map.keys(leaves))

    chats =
      socket.assigns.chats
      |> Enum.map(&if Enum.member?(chats_ids, &1.id), do: add_chat_members_count(&1), else: &1)

    socket |> fetch(chats)
  end

  def handle_info(info, socket) do
    Logger.warn("UNHANDLED INFO: #{inspect(info)}")
    {:noreply, socket}
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
    Logger.debug("Adding public chat: #{chat.title}")
    socket |> fetch([chat |> add_chat_members_count() | socket.assigns.chats])
  end

  defp update_public_chat(socket, chat) do
    idx = socket.assigns.chats |> Enum.find_index(&(&1.id == chat.id))

    case {chat.private, idx} do
      {true, nil} ->
        socket

      {true, _} ->
        Logger.debug("Removing private chat: #{chat.title}")
        socket |> fetch(socket.assigns.chats |> Enum.reject(&(&1.id == chat.id)))

      {false, nil} ->
        socket |> add_public_chat(chat)

      {false, _} ->
        Logger.debug("Updating public chat: #{chat.title}")

        socket
        |> fetch(
          socket.assigns.chats
          |> Enum.map(&if &1.id == chat.id, do: add_chat_members_count(chat), else: &1)
        )
    end
  end

  defp add_chat_members_count(chat), do: chat |> Map.put(:members, Chats.count_chat_members(chat))
end
