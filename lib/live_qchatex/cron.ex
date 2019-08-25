defmodule LiveQchatex.Cron do
  use GenServer
  require Logger
  alias LiveQchatex.Chats

  def start_link(_args) do
    state = %{chats: %{calls: 0, count: 0}, users: %{calls: 0, count: 0}}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    Logger.debug("Initializing cron tasks at #{self()}..")
    {:ok, state |> clean_chats() |> clean_users()}
  end

  def handle_info(:clean_chats, state), do: {:noreply, state |> clean_chats()}
  def handle_info(:clean_users, state), do: {:noreply, state |> clean_users()}

  defp clean_chats(%{chats: %{calls: calls, count: count}} = state) do
    # By reading the interval value here, we allow to dynamically take an updated config value
    interval = Application.get_env(:live_qchatex, :timers)[:cron_interval_clean_chats]

    Logger.debug(
      "[task-clean-chats][run=#{calls}] Purging chats older than #{interval / 60} minutes.."
    )

    purged = Chats.clear_chats(interval)

    Logger.debug(
      "[task-clean-chats][run=#{calls}] Purged #{purged} chats! Total purged: #{count + purged}"
    )

    Process.send_after(self(), :clean_chats, interval * 1000)
    update_counters(state, :chats, purged)
  end

  defp clean_users(%{users: %{calls: calls, count: count}} = state) do
    # By reading the interval value here, we allow to dynamically take an updated config value
    interval = Application.get_env(:live_qchatex, :timers)[:cron_interval_clean_users]

    Logger.debug(
      "[task-clean-users][run=#{calls}] Purging users older than #{interval / 60} minutes.."
    )

    purged = Chats.clear_users(interval)

    Logger.debug(
      "[task-clean-users][run=#{calls}] Purged #{purged} users! Total purged: #{count + purged}"
    )

    Process.send_after(self(), :clean_users, interval * 1000)
    update_counters(state, :users, purged)
  end

  defp update_counters(state, key, purged) do
    %{calls: calls, count: count} = Map.get(state, key)
    state |> Map.put(key, %{calls: calls + 1, count: count + purged})
  end
end
