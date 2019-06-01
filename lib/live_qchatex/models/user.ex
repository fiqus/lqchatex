defmodule LiveQchatex.Models.User do
  @moduledoc """
  User model module.
  """
  use Memento.Table,
    attributes: [:id, :socket_id, :nickname],
    index: [:socket_id],
    type: :ordered_set,
    autoincrement: true

  @typedoc """
  User struct
  """
  @type t :: %__MODULE__{
          id: nil | String.t(),
          socket_id: nil | String.t(),
          nickname: nil | String.t()
        }
end
