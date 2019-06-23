defmodule LiveQchatex.Chats do
  @moduledoc """
  The Chats context.
  """

  alias LiveQchatex.Repo
  alias LiveQchatex.Models
  alias LiveQchatex.Presence

  @topic inspect(__MODULE__)

  def topic, do: @topic
  def topic(%Models.Chat{} = chat), do: "#{@topic}/#{chat.id}"

  def subscribe, do: topic() |> subscribe()
  def subscribe(%Models.Chat{} = chat), do: chat |> topic() |> subscribe()
  def subscribe(topic), do: Repo.subscribe(topic)

  def track(%Models.Chat{} = chat, %Models.User{} = user) do
    subscribe()
    subscribe(chat)
    Presence.track_presence(self(), topic(chat), user.id, user |> Map.put(:typing, false))
  end

  @doc """
  Updates the last_activity of a given Memento.Table.record().

  ## Examples

      iex> update_last_activity(record)
      {:ok, record} | {:error, any()}

  """
  def update_last_activity(%{} = record) do
    record
    |> Map.put(:last_activity, utc_now())
    |> Repo.write()
  end

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
      created_at: now
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
  Clears older chats.
  """
  def clear_chats(timespan) do
    count = count_chats()
    {:ok, chats} = Repo.delete_all(Models.Chat, {:<=, :last_activity, utc_now() - timespan})

    found =
      chats
      |> clear_messages()
      |> length()

    if found > 0 do
      Repo.broadcast_all(count - found, @topic, [:chat, :cleared])
    end

    found
  end

  def clear_messages(chats) do
    chats
    |> Enum.map(fn %{:id => chat_id} ->
      {:ok, messages} = Repo.delete_all(Models.Message, {:==, :chat_id, chat_id})
      messages
    end)
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
    {:ok, users} = Repo.delete_all(Models.User, {:<=, :last_activity, utc_now() - timespan})
    found = length(users)

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

  def list_chat_members(chat) do
    topic(chat)
    |> Presence.list_presences()
  end

  def update_chat_member(%Models.Chat{} = chat, %Models.User{} = user) do
    Presence.update_presence(self(), topic(chat), user.id, user)
    chat
  end

  def update_member_typing(chat, user, is_typing) do
    Presence.update_presence(self(), topic(chat), user.id, %{typing: is_typing})
  end

  def utc_now(), do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix()

  def get_messages(%Models.Chat{} = chat) do
    {:ok, messages} = Repo.find(Models.Message, {:==, :chat_id, chat.id})
    messages
  end

  def create_room_message(chat, from_user, text) do
    {:ok, %{:id => chat_id}} = update_last_activity(chat)

    %Models.Message{chat_id: chat_id, from_user: from_user, text: text}
    |> create_message()
  end

  def create_private_message(from_user, to_user, text) do
    {:ok, _} = update_last_activity(from_user)

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
