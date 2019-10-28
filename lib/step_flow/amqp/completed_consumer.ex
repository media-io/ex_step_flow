defmodule StepFlow.Amqp.CompletedConsumer do
  @moduledoc """
  Consumer of all job with completed status.
  """

  require Logger
  alias StepFlow.Amqp.CompletedConsumer
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows
  alias StepFlow.Workflows.StepManager

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_completed",
    consumer: &CompletedConsumer.consume/4
  }

  @doc """
  Consume messages with completed topic, update Job status and continue the workflow.
  """
  def consume(channel, tag, _redelivered, %{"job_id" => job_id, "status" => status} = _payload) do
    Status.set_job_status(job_id, status)
    Workflows.notification_from_job(job_id)
    StepManager.check_step_status(%{job_id: job_id})
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job completed #{inspect(payload)}")
    Basic.ack(channel, tag)
  end
end
