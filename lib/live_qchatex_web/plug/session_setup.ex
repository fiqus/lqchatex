defmodule LiveQchatexWeb.Plug.SessionSetup do
  import Plug.Conn

  @key :sid

  def init(opts), do: opts

  def call(conn, _opts) do
    conn |> load_sid()
  end

  defp load_sid(conn), do: conn |> load_sid(get_session(conn, @key))
  defp load_sid(conn, nil), do: conn |> set_sid(LiveQchatex.Repo.random_string(256))
  defp load_sid(conn, sid), do: conn |> assign(@key, sid)

  defp set_sid(conn, sid), do: conn |> put_session(@key, sid) |> load_sid(sid)
end
