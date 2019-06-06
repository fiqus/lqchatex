defmodule LiveQchatex.Chats do
  @moduledoc """
  The Chats context.
  """

  alias LiveQchatex.Repo
  alias LiveQchatex.Models

  @topic inspect(__MODULE__)

  def subscribe, do: subscribe(@topic)
  def subscribe(%Models.Chat{} = chat), do: subscribe("#{@topic}/#{chat.id}")
  def subscribe(topic), do: Repo.subscribe(topic)

  @doc """
  Gets a single chat.

  Raises if the Chat does not exist.

  ## Examples

      iex> get_chat!(123)
      %Chat{}

      iex> get_chat!(456)
      ** (NoMatchError)

  """
  def get_chat!(id) do
    case Repo.read(Models.Chat, id) do
      {:ok, %Models.Chat{} = chat} -> chat
      {:error, err} -> raise err
    end
  end

  @doc """
  Creates a chat.

  ## Examples

      iex> create_chat(%{field: value})
      {:ok, %Chat{}}

      iex> create_chat(%{field: bad_value})
      {:error, any()}

  """
  def create_chat(attrs \\ %{}) do
    now = utc_now()

    %Models.Chat{
      id: Repo.random_string(64),
      title: "Untitled qchatex!",
      last_activity: now,
      created_at: now,
      members: %{}
    }
    |> write_chat_attrs(attrs)
    |> Repo.broadcast_event(@topic, [:chat, :created])
  end

  @doc """
  Updates a chat.

  ## Examples

      iex> update_chat(chat, %{field: new_value})
      {:ok, %Chat{}}

      iex> update_chat(chat, %{field: bad_value})
      {:error, any()}

  """
  def update_chat(%Models.Chat{} = chat, attrs) do
    chat
    |> write_chat_attrs(attrs)
    |> Repo.broadcast_event(@topic, [:chat, :updated])
  end

  @doc """
  Adds a member to a chat.
  """
  def add_chat_member(%Models.Chat{} = chat, %Models.User{} = user) do
    {:ok, chat} =
      chat
      |> Map.put(:members, chat.members |> Map.put(user.id, Models.User.foreign_fields(user)))
      |> Repo.write()

    Repo.broadcast(chat.members, "#{@topic}/#{chat.id}", [:chat, :members_updated])
    chat
  end

  @doc """
  Removes a member from a chat.
  """
  def remove_chat_member(%Models.Chat{} = chat, %Models.User{} = user) do
    {:ok, chat} =
      chat
      |> Map.put(:members, chat.members |> Map.delete(user.id))
      |> Repo.write()

    Repo.broadcast(chat.members, "#{@topic}/#{chat.id}", [:chat, :members_updated])
    chat
  end

  @doc """
  Deletes a Chat.

  ## Examples

      iex> delete_chat(chat)
      {:ok, %Chat{}}

      iex> delete_chat(chat)
      {:error, any()}

  """
  def delete_chat(%Models.Chat{} = chat) do
    chat
    |> Repo.delete()
    |> Repo.broadcast_event(@topic, [:chat, :deleted])
  end

  @doc """
  Clears older chats.
  """
  def clear_chats(timespan) do
    count = count_chats()
    {:ok, chats} = Repo.find(Models.Chat, {:<=, :last_activity, utc_now() - timespan})
    found = length(chats)
    # @TODO Remove chat messages!
    chats |> Enum.each(&Repo.delete(&1))

    if found > 0 do
      Repo.broadcast_all(count - found, @topic, [:chat, :cleared])
    end

    found
  end

  @doc """
  Returns the count of chats.

  ## Examples

      iex> count_chats()
      Integer

  """
  def count_chats, do: Repo.count(Models.Chat)

  defp write_chat_attrs(%Models.Chat{} = chat, attrs) do
    chat
    |> Repo.write(
      attrs
      # @TODO Improve this!
      |> Repo.to_atom_map()
      |> remove_empty(:title)
      |> remove_empty(:last_activity)
      |> remove_empty(:created_at)
    )
  end

  def get_or_create_user(sid) do
    case Repo.read(Models.User, sid) do
      {:ok, %Models.User{}} = ok -> ok
      {:error, %MatchError{}} -> create_user(sid)
      err -> err
    end
  end

  @doc """
  Creates an user.

  ## Examples

      iex> create_user(sid, %{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, any()}

  """
  def create_user(sid, attrs \\ %{}) do
    %Models.User{id: sid, nickname: "Unnamed", created_at: utc_now(), last_activity: utc_now()}
    |> write_user_attrs(attrs)
    |> Repo.broadcast_event(@topic, [:user, :created])
  end

  @doc """
  Updates an user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, any()}

  """
  def update_user(%Models.User{} = user, attrs) do
    user
    |> Map.put(:last_activity, utc_now())
    |> write_user_attrs(attrs)
    |> Repo.broadcast_event(@topic, [:user, :updated])
  end

  @doc """
  Clears older users.
  """
  def clear_users(timespan) do
    count = count_users()
    {:ok, users} = Repo.find(Models.User, {:<=, :last_activity, utc_now() - timespan})
    found = length(users)
    users |> Enum.each(&Repo.delete(&1))

    if found > 0 do
      Repo.broadcast_all(count - found, @topic, [:user, :cleared])
    end

    found
  end

  @doc """
  Returns the count of users.

  ## Examples

      iex> count_users()
      Integer

  """
  def count_users, do: Repo.count(Models.User)

  defp write_user_attrs(%Models.User{} = user, attrs) do
    user
    |> Repo.write(
      attrs
      # @TODO Improve this!
      |> Repo.to_atom_map()
      |> remove_empty(:nickname)
    )
  end

  def broadcast_user_typing(chat_id, user_id) do
    user_id
    |> Repo.broadcast_all("#{@topic}/#{chat_id}", [:user, :typing])
  end

  def utc_now(), do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix()

  def get_messages(%Models.Chat{} = chat) do
    {:ok, messages} = Repo.find(Models.Message, {:==, :chat_id, chat.id})
    messages
  end

  def create_room_message(chat_id, from_user, text) do
    %Models.Message{chat_id: chat_id, from_user: from_user, text: text}
    |> create_message()
  end

  def create_private_message(from_user, to_user, text) do
    %Models.Message{from_user: from_user, to_user: to_user, text: text}
    |> create_message()
  end

  defp create_message(%Models.Message{} = message) do
    message
    |> Map.put(
      :from_user,
      foreign_fields(&Models.User.foreign_fields/1, message.from_user)
    )
    |> Map.put(
      :to_user,
      foreign_fields(&Models.User.foreign_fields/1, message.to_user)
    )
    |> Map.put(:timestamp, utc_now())
    |> Repo.write()
    |> Repo.broadcast_event("#{@topic}/#{message.chat_id}", [:message, :created])
  end

  defp foreign_fields(_, nil), do: nil
  defp foreign_fields(func, data), do: func.(data)

  ######## HELPERS ########

  defp remove_empty(attrs, field) do
    if Map.get(attrs, field, "") |> empty_value?(),
      do: Map.delete(attrs, field),
      else: attrs
  end

  defp empty_value?(val) when val in [nil, ""], do: true
  defp empty_value?(_), do: false
end
