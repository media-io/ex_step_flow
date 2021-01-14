defmodule StepFlow.Amqp.WorkerStatusConsumer do
  @moduledoc """
  Consumer of all worker statuses.
  """

  require Logger
  alias StepFlow.Amqp.WorkerStatusConsumer
<<<<<<< HEAD
  alias StepFlow.Workflows
=======
>>>>>>> upstream/develop

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
