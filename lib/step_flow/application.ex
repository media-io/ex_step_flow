defmodule StepFlow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias StepFlow.Migration

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # Starts a worker by calling: StepFlow.Worker.start_link(arg)
      # {StepFlow.Worker, arg}
      supervisor(StepFlow.Repo, []),
      supervisor(StepFlow.Amqp.Supervisor, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StepFlow.Supervisor]
    supervisor = Supervisor.start_link(children, opts)
    Migration.All.apply_migrations()
    supervisor
  end
end
