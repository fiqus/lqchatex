defmodule LiveQchatexWeb.ChatView do
  use LiveQchatexWeb, :view

  def ellipsis(true), do: "<span class=\"ellipsis\"></span>"
  def ellipsis(false), do: nil

  def parse_timestamp(ts) when is_integer(ts) do
    {:ok, %DateTime{hour: hour, minute: minute, second: second}} = DateTime.from_unix(ts)
    format_date_values([hour, minute, second], ":")
  end

  def parse_timestamp(_), do: "-"

  defp format_date_values(values, glue),
    do:
      values
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.pad_leading(&1, 2, "0"))
      |> Enum.join(glue)
end
