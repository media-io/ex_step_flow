defmodule StepFlow.Amqp.WorkerInitializedConsumer do
  @moduledoc """
  Consumer of all worker inits.
  """

  require Logger
  alias StepFlow.Amqp.WorkerInitializedConsumer
  alias StepFlow.Jobs.Status
  alias StepFlow.Step.Live

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_initialized",
    prefetch_count: 1,
    consumer: &WorkerInitializedConsumer.consume/4
  }

  @doc """
  Consume worker initialized message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = payload
      ) do
    Status.set_job_status(job_id, "ready_to_start")
    Live.update_job_live(job_id)
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker initialized #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
