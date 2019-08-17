defmodule LiveQchatexWeb.LiveChat.User do
  use LiveQchatexWeb, :live_view

  @view_name "user-invite"

  def mount(%{sid: sid, path_params: %{"id" => user_id}}, socket) do
    setup_logger(socket, @view_name)

    try do
      from_user = Chats.get_user!(sid)
      to_user = Chats.get_user!(user_id)
      chat = generate_chat_and_invite_user(from_user, to_user)

      {:stop,
       socket
       # @TODO Make this message to be displayed on chat screen! (NOT WORKING)
       |> put_flash(:success, "The user was invited! Waiting to join..")
       |> redirect(to: Routes.live_path(socket, LiveQchatexWeb.LiveChat.Chat, chat.id))}
    rescue
      err ->
        Logger.error("Can't create the private chat with the user: #{inspect(err)}")

        {:stop,
         socket
         # @TODO Make this error to be displayed on home screen! (NOT WORKING)
         |> put_flash(:error, "Couldn't create the private chat with the user!")
         |> redirect(to: Routes.live_path(socket, LiveQchatexWeb.LiveChat.Home))}
    end
  end

  def render(assigns) do
    ~L(Redirecting to private chat..)
  end

  defp generate_chat_and_invite_user(from_user, to_user) do
    presence =
      LiveQchatex.Presence.list_presences(Chats.topic(:index, :chats))
      |> Enum.find(&is_chat_between_users?(&1, from_user.id, to_user.id))

    chat =
      case presence do
        %{key: chat_id} ->
          Chats.get_chat!(chat_id)

        _ ->
          chat_data = %{
            "title" => "Private chat between users",
            "private" => true
          }

          {:ok, chat} = Chats.create_chat(from_user, chat_data)
          chat
      end

    if !Chats.is_user_in_chat?(chat.id, to_user.id),
      do: Chats.private_chat_invite(chat, from_user, to_user)

    chat
  end

  defp is_chat_between_users?(presence, from_user_id, to_user_id),
    do:
      (presence.from_user == from_user_id and presence.to_user == to_user_id) or
        (presence.from_user == to_user_id and presence.to_user == from_user_id)
end
