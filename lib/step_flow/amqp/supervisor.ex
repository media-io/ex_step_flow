defmodule StepFlow.Amqp.Supervisor do
  require Logger
  use Supervisor

  @moduledoc """
  Supervisor of Step Flow.

  It manages AMQP connection to emit and consume messages as well as
  manages the StepManager to drive workflows.
  """

  @doc false
  def start_link do
    Logger.warn("#{__MODULE__} start_link")
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    Logger.warn("#{__MODULE__} init")

    children = [
      worker(StepFlow.Amqp.Connection, []),
      worker(StepFlow.Amqp.CompletedConsumer, []),
      worker(StepFlow.Amqp.ErrorConsumer, []),
      worker(StepFlow.Amqp.ProgressionConsumer, []),
      worker(StepFlow.Amqp.StoppedConsumer, []),
      worker(StepFlow.Amqp.WorkerDiscoveryConsumer, []),
      worker(StepFlow.Amqp.WorkerCreatedConsumer, []),
      worker(StepFlow.Amqp.WorkerInitializedConsumer, []),
      worker(StepFlow.Amqp.WorkerStartedConsumer, []),
      worker(StepFlow.Amqp.WorkerStatusConsumer, []),
      worker(StepFlow.Amqp.WorkerTerminatedConsumer, []),
      worker(StepFlow.Amqp.WorkerUpdatedConsumer, [])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
