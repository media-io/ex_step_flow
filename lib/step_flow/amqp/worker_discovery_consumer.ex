defmodule StepFlow.Amqp.WorkerDiscoveryConsumer do
  @moduledoc """
  Consumer of Worker Descriptions.
  """
  require Logger
  alias StepFlow.Amqp.WorkerDiscoveryConsumer
  alias StepFlow.WorkerDefinitions

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_discovery",
    exchange: "worker_response",
    prefetch_count: 1,
    consumer: &WorkerDiscoveryConsumer.consume/4
  }

  @doc """
  Consume messages, create Worker Definition if it's not already declared.
  """
  def consume(channel, tag, _redelivered, payload) do
    if WorkerDefinitions.exists(payload) do
      label = Map.get(payload, "label")
      version = Map.get(payload, "version")
      Logger.debug("don't re-register worker: #{label} #{version}")
      Basic.ack(channel, tag)
    else
      case WorkerDefinitions.create_worker_definition(payload) do
        {:ok, _} ->
          Basic.ack(channel, tag)

        {:error, reason} ->
          Logger.error("unable to register new worker: #{inspect(reason)}")
          Basic.nack(channel, tag)
      end
    end
  end
end
