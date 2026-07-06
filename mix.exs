defmodule ScoreTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :score_tracker,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      usage_rules: usage_rules(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      default_release: :score_tracker,
      releases: [
        score_tracker: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ScoreTracker.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
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
      {:bandit, "~> 1.12.0"},
      {:credo, "~> 1.7.18", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.2.0"},
      {:dotenvy, "~> 1.1.1"},
      {:ecto, "~> 3.14.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.4.5"},
      {:lazy_html, "~> 0.1.11", only: :test},
      {:mox, "~> 1.2.0", only: :test},
      {:nimble_options, "1.1.1"},
      {:phoenix, "~> 1.8.7"},
      {:phoenix_ecto, "~> 4.7.0"},
      {:phoenix_html, "~> 4.3.0"},
      {:phoenix_live_dashboard, "~> 0.8.7"},
      {:phoenix_live_reload, "~> 1.6.2", only: :dev},
      {:phoenix_live_view, "~> 1.2.5"},
      {:redix, "~> 1.5.3"},
      {:sobelow, "~> 0.14.1", only: [:dev, :test], runtime: false},
      {:telemetry_metrics, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.3.0"},
      {:esbuild, "~> 0.10.0", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.4.1", runtime: Mix.env() == :dev},
      {:usage_rules, "~> 1.2.6", only: [:dev]}
    ]
  end

  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [
        "usage_rules:all",
        "phoenix:ecto",
        "phoenix:elixir",
        "phoenix:html",
        "phoenix:liveview",
        "phoenix:phoenix"
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [&setup_env_file/1, "deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind score_tracker", "esbuild score_tracker"],
      "assets.deploy": [
        "tailwind score_tracker --minify",
        "esbuild score_tracker --minify",
        "phx.digest"
      ],
      check: [
        "format --check-formatted",
        "credo --strict",
        "sobelow --config"
      ],
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "credo --strict",
        "sobelow --config",
        "test"
      ]
    ]
  end

  defp setup_env_file(_) do
    System.cmd("cp", [".env.example", ".env"])
  end
end
