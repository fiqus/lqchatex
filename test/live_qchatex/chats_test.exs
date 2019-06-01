defmodule LiveQchatex.ChatsTest do
  use LiveQchatex.DataCase

  alias LiveQchatex.Chats
  alias LiveQchatex.Models

  describe "chats" do
    @valid_attrs %{title: "some title", expires: 1}
    @update_attrs %{title: "some updated title", expires: 10}
    @invalid_attrs %{title: nil, expires: -1}

    def chat_fixture(attrs \\ %{}) do
      {:ok, chat} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chats.create_chat()

      chat
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = chat_fixture()
      assert Chats.get_chat!(chat.id) == chat
    end

    test "create_chat/1 with empty data creates a chat with its defaults" do
      assert {:ok, %Models.Chat{} = chat} = Chats.create_chat()
      assert chat.title == "Untitled qchatex!"
      assert chat.expires == 60 * 60

      assert {:ok, %Models.Chat{} = chat} = Chats.create_chat(%{"title" => "", "expires" => ""})
      assert chat.title == "Untitled qchatex!"
      assert chat.expires == 60 * 60
    end

    test "create_chat/1 with valid data creates a chat" do
      assert {:ok, %Models.Chat{} = chat} = Chats.create_chat(@valid_attrs)
      assert chat.title == @valid_attrs.title
      assert chat.expires == @valid_attrs.expires
    end

    @tag :skip
    # @TODO Complete this test!
    test "create_chat/1 with invalid data returns error" do
      assert {:error, "error"} = Chats.create_chat(@invalid_attrs)
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = chat_fixture()
      assert {:ok, %Models.Chat{} = chat} = Chats.update_chat(chat, @update_attrs)
      assert chat.title == @update_attrs.title
      assert chat.expires == @update_attrs.expires
    end

    @tag :skip
    # @TODO Complete this test!
    test "update_chat/2 with invalid data returns error" do
      chat = chat_fixture()
      assert {:error, "error"} = Chats.update_chat(chat, @invalid_attrs)
      assert chat == Chats.get_chat!(chat.id)
    end

    test "delete_chat/1 deletes the chat" do
      chat = chat_fixture()
      assert {:ok, %Models.Chat{}} = Chats.delete_chat(chat)
      assert_raise MatchError, fn -> Chats.get_chat!(chat.id) end
    end
  end
end
