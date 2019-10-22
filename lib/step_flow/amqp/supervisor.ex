defmodule StepFlow.Amqp.Supervisor do
  require Logger
  use Supervisor

  @moduledoc """
  Supervisor of AMQP connections.
  """

  def start_link do
    Logger.warn("#{__MODULE__} start_link")
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.warn("#{__MODULE__} init")

    children = [
      worker(StepFlow.Amqp.Connection, []),
      worker(StepFlow.Amqp.CompletedConsumer, []),
      worker(StepFlow.Amqp.ErrorConsumer, []),
      worker(StepFlow.Amqp.WorkerDiscoveryConsumer, []),
      worker(StepFlow.Workflows.StepManager, [])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
