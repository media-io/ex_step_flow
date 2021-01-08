defmodule StepFlow.Amqp.WorkerStatusConsumer do
  @moduledoc """
  Consumer of all worker statuses.
  """

  require Logger
  alias StepFlow.Amqp.WorkerStatusConsumer
  alias StepFlow.Jobs.Status

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_status",
    prefetch_count: 1,
    consumer: &WorkerStatusConsumer.consume/4
  }

  @doc """
  Consume worker status message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = payload
      ) do
    Status.set_job_status(job_id, "processing")
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker status #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
