defmodule LiveQchatexWeb.LayoutView do
  use LiveQchatexWeb, :view

  def render_disclaimer(assigns) do
    render("disclaimer.html", assigns)
  end

  def timer_clean_chats(), do: :cron_interval_clean_chats |> get_timer()
  def timer_clean_users(), do: :cron_interval_clean_users |> get_timer()

  defp get_timer(key), do: Integer.floor_div(Application.get_env(:live_qchatex, :timers)[key], 60)
end
