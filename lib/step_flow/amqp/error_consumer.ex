defmodule StepFlow.Amqp.ErrorConsumer do
  require Logger

  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_error",
    consumer: &StepFlow.Amqp.ErrorConsumer.consume/4
  }

  def consume(channel, tag, _redelivered, %{"job_id" => job_id, "error" => description} = payload) do
    Logger.error("Job error #{inspect(payload)}")
    Status.set_job_status(job_id, "error", %{message: description})
    Workflows.notification_from_job(job_id)
    Basic.ack(channel, tag)
  end

  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id,
          "parameters" => [%{"id" => "message", "type" => "string", "value" => description}],
          "status" => "error"
        } = payload
      ) do
    Logger.error("Job error #{inspect(payload)}")
    Status.set_job_status(job_id, "error", %{message: description})
    Workflows.notification_from_job(job_id)
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job error #{inspect(payload)}")
    Basic.ack(channel, tag)
  end
end
