defmodule StepFlow.MixProject do
  use Mix.Project

  def project do
    [
      app: :step_flow,
      version: get_version(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),

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
      extra_applications: [
        :plug,
        :logger
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.8"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
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
    require Logger

    Logger.warn(
      "Calling out to `git describe` for the version number. This is slow! You should think about a hook to set the VERSION file"
    )

    System.cmd("git", ~w{describe --always --tags --first-parent})
    |> elem(0)
    |> String.trim()
  end
end
