defmodule StepFlow.Amqp.CompletedConsumer do
  @moduledoc """
  Consumer of all job with completed status.
  """
  require Logger
  alias StepFlow.Amqp.CompletedConsumer
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows.StepManager

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_completed",
    consumer: &CompletedConsumer.consume/4
  }

  def consume(channel, tag, _redelivered, %{"job_id" => job_id, "status" => status} = _payload) do
    Status.set_job_status(job_id, status)

    StepManager.check_step_status(%{job_id: job_id})
    Basic.ack(channel, tag)
  end
end
