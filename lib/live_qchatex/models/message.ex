defmodule LiveQchatex.Models.Message do
  @moduledoc """
  Message model module.
  """
  use Memento.Table,
    attributes: [:id, :from_socket, :to_socket, :text],
    index: [:from_socket, :to_socket],
    type: :ordered_set,
    autoincrement: true

  @typedoc """
  Message struct
  """
  @type t :: %__MODULE__{
          id: nil | String.t(),
          from_socket: nil | String.t(),
          to_socket: nil | String.t(),
          text: nil | String.t()
        }
end
