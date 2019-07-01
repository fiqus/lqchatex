defmodule LiveQchatex.Models.Chat do
  @moduledoc """
  Chat model module.
  """
  use Memento.Table,
    attributes: [:id, :user_id, :private, :title, :last_activity, :created_at],
    index: [:user_id, :private, :last_activity, :created_at],
    type: :ordered_set

  @typedoc """
  Chat struct
  """
  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          private: Boolean.t() | false,
          title: String.t(),
          last_activity: Integer.t(),
          created_at: DateTime.t()
        }
end
