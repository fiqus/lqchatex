defmodule LiveQchatex.Models.Message do
  @moduledoc """
  Message model module.
  """
  use Memento.Table,
    attributes: [:id, :chat_id, :from_user, :to_user, :text, :timestamp],
    index: [:chat_id, :from_user, :to_user],
    type: :ordered_set,
    autoincrement: true

  @typedoc """
  Message struct
  """
  @type t :: %__MODULE__{
          id: Integer.t(),
          chat_id: nil | String.t(),
          from_user: String.t(),
          to_user: nil | String.t(),
          text: String.t(),
          timestamp: DateTime.t()
        }
end
