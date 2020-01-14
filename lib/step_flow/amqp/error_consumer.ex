defmodule StepFlow.Amqp.ErrorConsumer do
  @moduledoc """
  Consumer of all job with error status.
  """

  require Logger

  alias StepFlow.Amqp.ErrorConsumer
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_error",
    consumer: &ErrorConsumer.consume/4
  }

  @doc """
  Consume message with error topic, update Job and send a notification
  """
  def consume(channel, tag, _redelivered, %{"job_id" => job_id, "error" => description} = payload) do
    Logger.error("Job error #{inspect(payload)}")
    Status.set_job_status(job_id, Status.state_enum_label(:error), %{message: description})
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
    Status.set_job_status(job_id, Status.state_enum_label(:error), %{message: description})
    Workflows.notification_from_job(job_id)
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job error #{inspect(payload)}")
    Basic.ack(channel, tag)
  end
end
