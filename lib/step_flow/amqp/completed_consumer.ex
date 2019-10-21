defmodule StepFlow.Amqp.CompletedConsumer do
  require Logger

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_completed",
    consumer: &StepFlow.Amqp.CompletedConsumer.consume/4
  }

  def consume(channel, tag, _redelivered, %{"job_id" => job_id, "status" => status} = _payload) do
    StepFlow.Jobs.Status.set_job_status(job_id, status)

    StepFlow.Workflows.StepManager.check_step_status(%{job_id: job_id})
    Basic.ack(channel, tag)
  end
end
