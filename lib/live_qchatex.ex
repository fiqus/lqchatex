defmodule LiveQchatex do
  @moduledoc """
  LiveQchatex keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defimpl String.Chars, for: PID do
    def to_string(pid) do
      info = Process.info(pid)
      name = info[:registered_name]

      "#{name}-#{inspect(pid)}"
    end
  end
end
