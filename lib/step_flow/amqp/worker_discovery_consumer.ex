defmodule StepFlow.Amqp.WorkerDiscoveryConsumer do
  @moduledoc """
  Consumer of worker descriptions.
  """
  require Logger
  alias StepFlow.Amqp.WorkerDiscoveryConsumer
  alias StepFlow.WorkerDefinitions

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_discovery",
    consumer: &WorkerDiscoveryConsumer.consume/4
  }

  def consume(channel, tag, _redelivered, payload) do
    if not WorkerDefinitions.exists(payload) do
      case WorkerDefinitions.create_worker_definition(payload) do
        {:ok, _} -> Basic.ack(channel, tag)
        {:error, reason} ->
          Logger.error("unable to register new worker: #{inspect reason}")
          Basic.nack(channel, tag)
      end
    else
      label = Map.get(payload, "label")
      version = Map.get(payload, "version")
      Logger.debug("don't re-register worker: #{label} #{version}")
    end
  end
end
