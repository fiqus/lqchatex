defmodule LiveQchatex.Models.Message do
  @moduledoc """
  Message model module.
  """
  use Memento.Table,
    attributes: [:id, :chat_id, :user, :text, :timestamp],
    index: [:chat_id],
    type: :ordered_set,
    autoincrement: true

  @typedoc """
  Message struct
  """
  @type t :: %__MODULE__{
          id: Integer.t(),
          chat_id: String.t(),
          user: String.t(),
          text: String.t(),
          timestamp: DateTime.t()
        }
end
