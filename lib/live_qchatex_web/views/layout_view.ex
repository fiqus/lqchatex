defmodule LiveQchatexWeb.LayoutView do
  use LiveQchatexWeb, :view

  def render_disclaimer(assigns), do: render("disclaimer.html", assigns)

  def render_version(),
    # do: "Live Qchatex <b>v#{get_app_version()}.#{get_commit_date()}</b> at #{get_commit_link()}"
    do: "Live Qchatex <b>v#{get_app_version()}</b>"

  def repo_url(path \\ ""),
    do: Application.get_env(:live_qchatex, LiveQchatexWeb.Endpoint)[:repo] <> path

  def timer_clean_chats(), do: :cron_interval_clean_chats |> get_timer()
  def timer_clean_users(), do: :cron_interval_clean_users |> get_timer()

  defp get_timer(key), do: Integer.floor_div(Application.get_env(:live_qchatex, :timers)[key], 60)

  defp get_app_version(), do: Application.spec(:live_qchatex, :vsn)
  defp get_commit_sha(), do: System.cmd("git", ["rev-parse", "HEAD"]) |> elem(0) |> String.trim()

  defp get_commit_link() do
    commit_sha = get_commit_sha()
    path = "/commit/#{commit_sha}"

    "<a href=\"#{repo_url(path)}\" target=\"_blank\">##{commit_sha}</a>"
  end

  defp get_commit_date() do
    [sec, tz] =
      System.cmd("git", ~w|log -1 --date=raw --format=%cd|)
      |> elem(0)
      |> String.split(~r/\s+/, trim: true)
      |> Enum.map(&String.to_integer/1)

    DateTime.from_unix!(sec + tz * 36)
  end
end
