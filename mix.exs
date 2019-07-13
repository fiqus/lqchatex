defmodule LiveQchatex.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_qchatex,
      version: "0.1.1",
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
      extra_applications: [:logger, :runtime_tools]
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
      {:phoenix_live_view, github: "phoenixframework/phoenix_live_view"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:guardian, "~> 1.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:memento, "~> 0.3.1"}
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
      "mnesia.reset": fn _ -> reset_mnesia(Mix.env()) end
    ]
  end

  defp reset_mnesia(:prod), do: Mix.raise("Can't reset mnesia on production!")

  defp reset_mnesia(_) do
    IO.puts("Removing '.mnesia' directory..")
    Mix.shell().cmd("rm -rf .mnesia")
  end
end
