defmodule LiveQchatexWeb.ChatView do
  use LiveQchatexWeb, :view

  def elipses(true), do: "..."
  def elipses(false), do: nil
end
