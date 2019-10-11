defmodule StepFlow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # Starts a worker by calling: StepFlow.Worker.start_link(arg)
      # {StepFlow.Worker, arg}
      supervisor(StepFlow.Repo, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StepFlow.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
