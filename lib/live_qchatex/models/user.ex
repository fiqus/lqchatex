defmodule LiveQchatex.Models.User do
  @moduledoc """
  User model module.
  """
  use Memento.Table,
    attributes: [:id, :nickname, :last_activity, :created_at],
    index: [:last_activity, :created_at],
    type: :ordered_set

  @typedoc """
  User struct
  """
  @type t :: %__MODULE__{
          id: String.t(),
          nickname: String.t(),
          last_activity: Integer.t(),
          created_at: DateTime.t()
        }

  def foreign_fields(%__MODULE__{} = user),
    do: %{
      id: user.id,
      nickname: user.nickname
    }
end
