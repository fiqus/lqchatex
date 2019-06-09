defmodule LiveQchatexWeb.ChatView do
  use LiveQchatexWeb, :view

  def ellipsis(true), do: "<span class=\"ellipsis\"></span>"
  def ellipsis(false), do: nil
end
