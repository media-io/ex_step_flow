defmodule StepFlow.Amqp.WorkerStatusConsumer do
  @moduledoc """
  Consumer of all worker statuses.
  """

  require Logger
  alias StepFlow.Amqp.WorkerStatusConsumer

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_status",
    exchange: "worker_response",
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
          "job_id" => _job_id
        } = _payload
      ) do
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker status #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
