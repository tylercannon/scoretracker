defmodule Ripple.MixProject do
  use Mix.Project

  def project do
    [
      app: :ripple,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Ripple.Application, []},
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
      {:phoenix, "1.7.21"},
      {:phoenix_html, "4.2.1"},
      {:phoenix_live_reload, "1.6.0", only: :dev},
      {:phoenix_live_view, "1.1.2"},
      {:lazy_html, "0.1.3", only: :test},
      {:phoenix_live_dashboard, "0.8.7"},
      {:ecto, "3.13.2"},
      {:phoenix_ecto, "4.6.5"},
      {:esbuild, "0.10.0", runtime: Mix.env() == :dev},
      {:tailwind, "0.3.1", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.3.0"},
      {:jason, "1.4.4"},
      {:dns_cluster, "0.2.0"},
      {:bandit, "1.7.0"},
      {:nimble_options, "1.1.1"}
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
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind ripple", "esbuild ripple"],
      "assets.deploy": [
        "tailwind ripple --minify",
        "esbuild ripple --minify",
        "phx.digest"
      ]
    ]
  end
end
