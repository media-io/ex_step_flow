defmodule StepFlow.Amqp.WorkerTerminatedConsumer do
  @moduledoc """
  Consumer of all worker terminations.
  """

  require Logger
  alias StepFlow.Amqp.WorkerTerminatedConsumer
  alias StepFlow.Jobs.Status

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_terminated",
    prefetch_count: 1,
    consumer: &WorkerTerminatedConsumer.consume/4
  }

  @doc """
  Consume worker terminated message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = payload
      ) do
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker terminated #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
