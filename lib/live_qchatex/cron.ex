defmodule LiveQchatex.Cron do
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def init(state) do
    Logger.debug("Initializing cron tasks..")
    clean_chats()
    clean_users()
    {:ok, state}
  end

  def handle_info(:clean_chats, state) do
    clean_chats()
    {:noreply, state}
  end

  def handle_info(:clean_users, state) do
    clean_users()
    {:noreply, state}
  end

  defp clean_chats() do
    interval_clean_chats = Application.get_env(:live_qchatex, :timers)[:cron_interval_clean_chats]

    Logger.debug(
      "[task-clean-chats] Purging chats older than #{interval_clean_chats / 60} minutes.."
    )

    count = LiveQchatex.Chats.clear_chats(interval_clean_chats)
    Logger.debug("[task-clean-chats] Purged #{count} chats!")
    Process.send_after(self(), :clean_chats, interval_clean_chats * 1000)
  end

  defp clean_users() do
    interval_clean_users = Application.get_env(:live_qchatex, :timers)[:cron_interval_clean_users]

    Logger.debug(
      "[task-clean-users] Purging users older than #{interval_clean_users / 60} minutes.."
    )

    count = LiveQchatex.Chats.clear_users(interval_clean_users)
    Logger.debug("[task-clean-users] Purged #{count} users!")
    Process.send_after(self(), :clean_users, interval_clean_users * 1000)
  end
end
