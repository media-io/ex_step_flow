defmodule StepFlow.Amqp.WorkerUpdatedConsumer do
  @moduledoc """
  Consumer of all worker updates.
  """

  require Logger
  alias StepFlow.Amqp.WorkerUpdatedConsumer
  alias StepFlow.Jobs.Status

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_updated",
    prefetch_count: 1,
    consumer: &WorkerUpdatedConsumer.consume/4
  }

  @doc """
  Consume worker updated message.
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
    Logger.error("Worker updated #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
