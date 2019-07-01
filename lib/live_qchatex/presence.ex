defmodule LiveQchatex.Presence do
  use Phoenix.Presence,
    otp_app: :live_qchatex,
    pubsub_server: LiveQchatex.PubSub

  alias LiveQchatex.Presence

  def track_presence(pid, topic, key, payload),
    do: Presence.track(pid, topic, key, payload)

  def update_presence(pid, topic, key, payload) do
    metas =
      Presence.get_by_key(topic, key)[:metas]
      |> List.first()
      |> Map.merge(payload)

    Presence.update(pid, topic, key, metas)
  end

  def list_presences(topic) do
    Presence.list(topic)
    |> Enum.map(fn {_, data} ->
      data[:metas]
      |> List.first()
    end)
  end

  def count_presences(topic) do
    Presence.list(topic) |> Map.keys() |> length()
  end
end
