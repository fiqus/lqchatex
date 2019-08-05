defmodule LiveQchatex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    # Load application version
    load_version()

    # List all child processes to be supervised
    children = [
      # Start the application repository
      LiveQchatex.Repo,
      # Start the endpoint when the application starts
      LiveQchatexWeb.Endpoint,
      # Start the presence worker
      LiveQchatex.Presence,
      # Start the cron tasks worker
      LiveQchatex.Cron
      # Starts a worker by calling: LiveQchatex.Worker.start_link(arg)
      # {LiveQchatex.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveQchatex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LiveQchatexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def get_repo_pid() do
    Process.whereis(LiveQchatex.Repo)
  end

  def env, do: Application.get_env(:live_qchatex, LiveQchatexWeb.Endpoint)[:environment]
  def env?(environment), do: env() == environment

  def version, do: Application.get_env(:live_qchatex, :version)
  def version(key), do: version()[key]

  defp load_version() do
    [vsn, hash, date] =
      case File.read("VERSION") do
        {:ok, data} -> data |> String.split("\n")
        _ -> [nil, nil, nil]
      end

    version = %{vsn: vsn, hash: hash, date: date}
    Logger.info("Loading app version: #{inspect(version)}", ansi_color: :yellow)

    Application.put_env(:live_qchatex, :version, version)
  end
end
