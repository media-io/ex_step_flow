defmodule StepFlow.MixProject do
  use Mix.Project

  def project do
    [
      app: :step_flow,
      version: get_version(),
      elixir: "~> 1.6",
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
        :blue_bird,
        :jason,
        :logger,
        :phoenix,
        :plug,
        :postgrex
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:blue_bird, "~> 0.4.1"},
      {:cowboy, "~> 2.6"},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.1"},
      {:ecto_sql, "~> 3.1"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:gettext, "~> 0.14"},
      {:jason, "~> 1.1"},
      {:phoenix, "~> 1.4"},
      {:phoenix_html, "~> 2.10"},
      {:plug, "~> 1.8"},
      {:postgrex, "~> 0.15.0"}
    ]
  end

  defp description() do
    "Step flow manager for Elixir applications"
  end

  defp package() do
    [
      name: "step_flow",
      files: ["lib", "mix.exs", "README*", "LICENSE*", "VERSION"],
      maintainers: [
        "Valentin Noël",
        "Marc-Antoine Arnaud"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/media-io/ex_step_flow"}
    ]
  end

  defp get_version do
    version_from_file()
    |> handle_file_version()
    |> String.replace_leading("v", "")
  end

  defp version_from_file(file \\ "VERSION") do
    File.read(file)
  end

  defp handle_file_version({:ok, content}) do
    content
  end

  defp handle_file_version({:error, _}) do
    retrieve_version_from_git()
  end

  defp retrieve_version_from_git do
    System.cmd("git", ~w{describe --always --tags --first-parent})
    |> elem(0)
    |> String.trim()
  end

  defp aliases do
    [
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      checks: [
        "ecto.create --quiet",
        "test",
        "format --check-formatted",
        "credo --strict"
      ]
    ]
  end
end
