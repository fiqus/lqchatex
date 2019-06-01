defmodule LiveQchatex.Models.Chat do
  @moduledoc """
  Chat model module.
  """
  use Memento.Table,
    attributes: [:id, :socket_id, :title, :expires],
    index: [:socket_id, :expires],
    type: :ordered_set,
    autoincrement: true

  @typedoc """
  Chat struct
  """
  @type t :: %__MODULE__{
          id: nil | String.t(),
          socket_id: nil | String.t(),
          title: nil | String.t(),
          expires: nil | String.t()
        }
end
