defmodule LiveQchatex.ChatsTest do
  use LiveQchatex.DataCase

  alias LiveQchatex.Chats
  alias LiveQchatex.Models

  describe "Chats module" do
    @chat_valid_attrs %{title: "some title", last_activity: 1, created_at: 1}
    @chat_update_attrs %{title: "some updated title", last_activity: 10, created_at: 10}
    @user_sid "user-session-id"
    @user_valid_attrs %{nickname: "testnick", last_activity: 1, created_at: 1}

    def chat_fixture(attrs \\ %{}) do
      {:ok, chat} =
        attrs
        |> Enum.into(@chat_valid_attrs)
        |> Chats.create_chat()

      chat
    end

    def message_fixture(%Models.Chat{} = chat, from_user \\ %Models.User{}) do
      {:ok, message} = Chats.create_room_message(chat, from_user, "Test message!")
      message
    end

    def user_fixture(attrs \\ %{}) do
      {:ok, user} = Chats.create_user(@user_sid, Enum.into(attrs, @user_valid_attrs))
      user
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = chat_fixture()
      assert Chats.get_chat!(chat.id) == chat
    end

    test "create_chat/1 with empty data creates a chat with its defaults" do
      now = Chats.utc_now()
      assert {:ok, %Models.Chat{} = chat} = Chats.create_chat()
      assert chat.title == "Untitled qchatex!"
      assert chat.last_activity <= now
      assert chat.created_at <= now

      assert {:ok, %Models.Chat{} = chat} =
               Chats.create_chat(%{"title" => "", "last_activity" => "", "created_at" => ""})

      assert chat.title == "Untitled qchatex!"
      assert chat.last_activity <= now
      assert chat.created_at <= now
    end

    test "create_chat/1 with valid data creates a chat" do
      assert {:ok, %Models.Chat{} = chat} = Chats.create_chat(@chat_valid_attrs)
      assert chat.title == @chat_valid_attrs.title
      assert chat.last_activity == @chat_valid_attrs.last_activity
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = chat_fixture()
      assert {:ok, %Models.Chat{} = chat} = Chats.update_chat(chat, @chat_update_attrs)
      assert chat.title == @chat_update_attrs.title
      assert chat.last_activity == @chat_update_attrs.last_activity
    end

    test "clear_chats/1 clears chats and messages older than given timespan" do
      Repo.delete_all(Models.Chat)
      Repo.delete_all(Models.Message)
      chat = chat_fixture()
      message_fixture(chat)
      assert 1 = Chats.clear_chats(-1)
      assert [] = Chats.get_messages(chat)
      assert_raise MatchError, fn -> Chats.get_chat!(chat.id) end
    end

    test "clear_users/1 clears users older than given timespan" do
      Repo.delete_all(Models.User)
      user_fixture()
      assert 1 = Chats.clear_users(-1)
      assert 0 = Chats.count_users()
    end
  end
end
