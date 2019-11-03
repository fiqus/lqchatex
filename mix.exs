defmodule LiveQchatex.MixProject do
  use Mix.Project

  @github_url "https://github.com/fiqus/lqchatex"
  @demo_url "https://lqchatex.fiqus.coop"
  @version "0.2.1"

  def project do
    [
      app: :live_qchatex,
      version: @version,
      name: "LiveQchatex",
      description:
        "Very simple and quick chat engine that allows you to create and join chat rooms on-the-fly.",
      source_url: @github_url,
      homepage_url: @github_url,
      demo_url: @demo_url,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coverage: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveQchatex.Application, []},
      extra_applications: [:logger, :runtime_tools, :mnesia]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.3"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:guardian, "~> 1.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:memento, "~> 0.3"},
      {:libcluster, "~> 3.0"}
    ]
  end

  # App releases configuration.
  defp releases do
    [
      lqchatex: [
        include_executables_for: [:unix, :windows],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      coverage: ["coveralls.html"],
      "deps.get": ["deps.get", &update_version/1],
      "mnesia.reset": fn _ -> reset_mnesia(Mix.env()) end
    ]
  end

  defp reset_mnesia(:prod), do: Mix.raise("Can't reset mnesia on production!")

  defp reset_mnesia(_) do
    Mix.shell().info("Removing '.mnesia' directory..")
    Mix.shell().cmd("rm -rf .mnesia")
  end

  defp update_version(_) do
    contents = [
      @version,
      get_commit_sha(),
      get_commit_date()
    ]

    Mix.shell().info("\e[33mUpdating app version with: #{inspect(contents)}\e[39m")
    File.write("VERSION", Enum.join(contents, "\n"), [:write])
  end

  defp get_commit_sha(), do: System.cmd("git", ["rev-parse", "HEAD"]) |> elem(0) |> String.trim()

  defp get_commit_date() do
    [sec, tz] =
      System.cmd("git", ~w|log -1 --date=raw --format=%cd|)
      |> elem(0)
      |> String.split(~r/\s+/, trim: true)
      |> Enum.map(&String.to_integer/1)

    DateTime.from_unix!(sec + tz * 36)
  end
end
