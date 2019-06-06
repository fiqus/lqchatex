defmodule LiveQchatex.Models.Chat do
  @moduledoc """
  Chat model module.
  """
  use Memento.Table,
    attributes: [:id, :socket_id, :title, :last_activity, :created_at, :members],
    index: [:socket_id, :last_activity, :created_at],
    type: :ordered_set

  @typedoc """
  Chat struct
  """
  @type t :: %__MODULE__{
          id: String.t(),
          socket_id: nil | String.t(),
          title: String.t(),
          last_activity: Integer.t(),
          created_at: DateTime.t(),
          members: Map.t()
        }
end
