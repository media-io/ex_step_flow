defmodule StepFlow.Amqp.WorkerStartedConsumer do
  @moduledoc """
  Consumer of all worker starts.
  """

  require Logger
  alias StepFlow.Amqp.WorkerStartedConsumer
  alias StepFlow.Jobs.Status
<<<<<<< HEAD
  alias StepFlow.Step.Live
  alias StepFlow.Workflows
  alias StepFlow.Workflows.StepManager
=======
>>>>>>> upstream/develop

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_started",
    prefetch_count: 1,
    consumer: &WorkerStartedConsumer.consume/4
  }

  @doc """
  Consume worker started message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = _payload
      ) do
    Status.set_job_status(job_id, "processing")
    Workflows.notification_from_job(job_id)
    StepManager.check_step_status(%{job_id: job_id})
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker started #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
