defmodule LiveQchatex.Chats do
  @moduledoc """
  The Chats context.
  """
  require Logger
  alias LiveQchatex.Repo
  alias LiveQchatex.Models
  alias LiveQchatex.Presence

  @topic inspect(__MODULE__)

  def topic, do: "#{@topic}/global"
  def topic(:presence, :chats), do: "#{@topic}/chats/presence"
  def topic(%Models.Chat{} = chat), do: "#{@topic}/chats/#{chat.id}"

  def subscribe, do: topic() |> subscribe()
  def subscribe(:presence, :chats), do: topic(:presence, :chats) |> subscribe()
  def subscribe(%Models.Chat{} = chat), do: chat |> topic() |> subscribe()
  def subscribe(topic), do: Repo.subscribe(topic)

  def track(%Models.Chat{} = chat, %Models.User{} = user) do
    Presence.track_presence(self(), topic(chat), user.id, user |> Map.put(:typing, false))

    Presence.track_presence(self(), topic(:presence, :chats), chat.id, %{
      pid: self(),
      user: user.id
    })

    subscribe(chat)
    hearthbeat(chat)
    track(user)
  end

  def track(%Models.User{} = user) do
    subscribe()
    hearthbeat(user)
  end

  @doc """
  Updates the last_activity of a given Memento.Table.record().

  ## Examples

      iex> update_last_activity!(record)
      record | raise

  """
  def update_last_activity!(%{} = record) do
    {:ok, result} = record |> Repo.update(%{last_activity: utc_now()})
    result
  end

  def handle_hearthbeat({:hearthbeat, :chat, chat_id}, state),
    do: hearthbeat(%Models.Chat{id: chat_id}, state)

  def handle_hearthbeat({:hearthbeat, :user, user_id}, state),
    do: hearthbeat(%Models.User{id: user_id}, state)

  defp hearthbeat(model, state) do
    model |> update_last_activity!() |> hearthbeat()
    {:noreply, state}
  end

  defp hearthbeat(%Models.Chat{} = chat) do
    interval = Application.get_env(:live_qchatex, :timers)[:cron_interval_clean_chats] |> div(2)

    Logger.debug("[chats] Sending CHAT hearthbeat every #{interval} seconds..")

    Process.send_after(self(), {:hearthbeat, :chat, chat.id}, interval * 1000)
  end

  defp hearthbeat(%Models.User{} = user) do
    interval = Application.get_env(:live_qchatex, :timers)[:cron_interval_clean_users] |> div(2)

    Logger.debug("[chats] Sending USER hearthbeat every #{interval} seconds..")

    Process.send_after(self(), {:hearthbeat, :user, user.id}, interval * 1000)
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

  def get_public_chats() do
    {:ok, chats} = Repo.find(Models.Chat, {:!=, :private, true})

    chats |> Enum.sort(&(&1.created_at >= &2.created_at))
  end

  def count_chat_members(chat), do: chat |> topic() |> Presence.count_presences()

  @doc """
  Creates a chat.

  ## Examples

      iex> create_chat(%Models.User{id: "..."}, %{field: value})
      {:ok, %Chat{}}

      iex> create_chat(%Models.User{id: "..."}, %{field: bad_value})
      {:error, any()}

  """
  def create_chat(%Models.User{} = user, attrs \\ %{}) do
    now = utc_now()

    %Models.Chat{
      id: Repo.random_string(64),
      user_id: user.id,
      title: "Untitled qchatex!",
      last_activity: now,
      created_at: now
    }
    |> write_chat_attrs(attrs)
    |> Repo.broadcast_event(topic(), [:chat, :created])
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
    |> Repo.broadcast_event(topic(), [:chat, :updated])
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
      Repo.broadcast_all(count - found, topic(), [:chat, :cleared])
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
      |> sanitize_attrs()
      # @TODO Improve this!
      |> Repo.to_atom_map()
      |> parse_bool(:private)
      |> remove_empty(:user_id)
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
    |> Repo.broadcast_event(topic(), [:user, :created])
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
    |> Repo.broadcast_event(topic(), [:user, :updated])
  end

  @doc """
  Clears older users.
  """
  def clear_users(timespan) do
    count = count_users()
    {:ok, users} = Repo.delete_all(Models.User, {:<=, :last_activity, utc_now() - timespan})
    found = length(users)

    if found > 0 do
      Repo.broadcast_all(count - found, topic(), [:user, :cleared])
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
      |> sanitize_attrs()
      # @TODO Improve this!
      |> Repo.to_atom_map()
      |> remove_empty(:nickname)
    )
  end

  def list_chat_members(chat), do: chat |> topic() |> Presence.list_presences()

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

  def create_message(chat, from_user, text) do
    chat = chat |> update_last_activity!()

    %Models.Message{chat_id: chat.id, text: text}
    |> Map.put(
      :from_user,
      foreign_fields(&Models.User.foreign_fields/1, from_user)
    )
    |> Map.put(:timestamp, utc_now())
    |> Repo.write()
    |> Repo.broadcast_event(topic(chat), [:message, :created])
  end

  defp foreign_fields(_, nil), do: nil
  defp foreign_fields(func, data), do: func.(data)

  ######## HELPERS ########

  defp sanitize_attrs(attrs) do
    attrs
    |> Enum.map(fn
      {k, v} when is_binary(v) ->
        {k, v |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()}

      a ->
        a
    end)
  end

  defp parse_bool(attrs, field) do
    value =
      case Map.get(attrs, field, false) do
        v when v in [true, "true"] -> true
        _ -> false
      end

    attrs |> Map.put(field, value)
  end

  defp remove_empty(attrs, field) do
    if Map.get(attrs, field, "") |> empty_value?(),
      do: Map.delete(attrs, field),
      else: attrs
  end

  defp empty_value?(val) when val in [nil, ""], do: true
  defp empty_value?(_), do: false
end
