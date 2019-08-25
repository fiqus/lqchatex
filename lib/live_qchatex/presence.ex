defmodule LiveQchatex.Presence do
  use Phoenix.Presence,
    otp_app: :live_qchatex,
    pubsub_server: LiveQchatex.PubSub

  alias LiveQchatex.Presence

  def track_presence(pid, topic, key, payload),
    do: Presence.track(pid, topic, key, payload)

  def untrack_presence(pid, topic, key),
    do: Presence.untrack(pid, topic, key)

  def update_presence(pid, topic, key, payload) do
    metas = topic |> get_presence(key) |> Map.merge(payload)
    Presence.update(pid, topic, key, metas)
  end

  def get_presence(topic, key) do
    case Presence.get_by_key(topic, key) do
      %{metas: metas} -> metas |> List.first()
      _ -> nil
    end
  end

  def list_presences(topic),
    do:
      Presence.list(topic)
      |> Enum.map(fn {key, %{metas: metas}} ->
        metas |> List.first() |> Map.merge(%{key: key})
      end)

  def count_presences(topic),
    do: Presence.list(topic) |> Map.keys() |> length()
end
