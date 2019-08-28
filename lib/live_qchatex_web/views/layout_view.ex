defmodule LiveQchatexWeb.LayoutView do
  use LiveQchatexWeb, :view

  def render_counters(assigns), do: render("counters.html", assigns)
  def render_disclaimer(assigns), do: render("disclaimer.html", assigns)
  def render_invites(assigns), do: render("invites.html", assigns)

  def render_version(),
    do: "Live Qchatex <b>v#{get_app_version()}.#{get_commit_date()}</b> at #{get_commit_link()}"

  def repo_url(path \\ ""),
    do: Application.get_env(:live_qchatex, LiveQchatexWeb.Endpoint)[:repo] <> path

  def demo_url(path \\ ""),
    do: Application.get_env(:live_qchatex, LiveQchatexWeb.Endpoint)[:demo] <> path

  def timer_clean_chats(), do: :cron_interval_clean_chats |> get_timer()
  def timer_clean_users(), do: :cron_interval_clean_users |> get_timer()

  defp get_timer(key), do: Integer.floor_div(Application.get_env(:live_qchatex, :timers)[key], 60)

  defp get_app_version(), do: Application.spec(:live_qchatex, :vsn)
  defp get_commit_sha(), do: LiveQchatex.Application.version(:hash)
  defp get_commit_date(), do: LiveQchatex.Application.version(:date)

  defp get_commit_link() do
    commit_sha = get_commit_sha()
    path = "/commit/#{commit_sha}"

    "<a href=\"#{repo_url(path)}\" target=\"_blank\">##{commit_sha}</a>"
  end
end
