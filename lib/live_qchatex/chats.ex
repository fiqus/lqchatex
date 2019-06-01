defmodule LiveQchatex.Chats do
  @moduledoc """
  The Chats context.
  """

  alias LiveQchatex.Repo
  alias LiveQchatex.Models

  @topic inspect(__MODULE__)

  def subscribe do
    Repo.subscribe(@topic)
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
    %Models.Chat{id: Repo.random_string(64), title: "Untitled qchatex!", expires: 60 * 60}
    |> Repo.write(
      attrs
      # @TODO Improve this!
      |> Repo.to_atom_map()
      |> remove_empty(:title)
      |> remove_empty(:expires)
    )
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
    |> Repo.write(attrs)
    |> Repo.broadcast_event(@topic, [:chat, :updated])
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
  Returns the count of chats.

  ## Examples

      iex> count_chats()
      Integer

  """
  def count_chats, do: Repo.count(Models.Chat)

  def create_user(sid, attrs \\ %{}) do
    %Models.User{id: sid, nickname: "Unnamed"}
    |> Repo.write(
      attrs
      |> Repo.to_atom_map()
      |> remove_empty(:nickname)
    )
    |> Repo.broadcast_event(@topic, [:user, :created])
  end

  @doc """
  Returns the count of users.

  ## Examples

      iex> count_users()
      Integer

  """
  def count_users, do: Repo.count(Models.User)

  ######## HELPERS ########

  defp remove_empty(attrs, field) do
    if Map.get(attrs, field, "") |> empty_value?(),
      do: Map.delete(attrs, field),
      else: attrs
  end

  defp empty_value?(val) when val in [nil, ""], do: true
  defp empty_value?(_), do: false
end
