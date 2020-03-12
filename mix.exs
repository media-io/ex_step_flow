defmodule StepFlow.MixProject do
  use Mix.Project

  def project do
    [
      app: :step_flow,
      version: "0.0.17",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: package(),
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),

      # Docs
      name: "StepFlow",
      source_url: "https://github.com/media-io/ex_step_flow",
      homepage_url: "https://github.com/media-io/ex_step_flow",
      docs: [
        main: "StepFlow",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {StepFlow.Application, []},
      extra_applications: [
        :amqp,
        :blue_bird,
        :httpoison,
        :jason,
        :logger,
        :phoenix,
        :plug,
        :postgrex,
        :slack,
        :timex
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 1.4"},
      {:blue_bird, "~> 0.4.1"},
      {:cowboy, "~> 2.6"},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.1"},
      {:ecto_sql, "~> 3.1"},
      {:ecto_enum, "~> 1.4"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:ex_json_schema, "~> 0.7.3"},
      {:fake_server, "~> 2.1", only: :test},
      {:gettext, "~> 0.14"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.1"},
      {:phoenix, "~> 1.4"},
      {:phoenix_html, "~> 2.10"},
      {:plug, "~> 1.8"},
      {:postgrex, "~> 0.15.0"},
      {:slack, "~> 0.20.0"},
      {:timex, "~> 3.2"}
    ]
  end

  defp description() do
    "Step flow manager for Elixir applications"
  end

  defp package() do
    [
      name: "step_flow",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: [
        "Valentin Noël",
        "Marc-Antoine Arnaud"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/media-io/ex_step_flow"}
    ]
  end

  defp aliases do
    [
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "test"],
      checks: [
        "ecto.create --quiet",
        "test",
        "format --check-formatted",
        "credo --strict"
      ]
    ]
  end
end
