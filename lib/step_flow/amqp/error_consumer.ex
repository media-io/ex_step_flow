defmodule StepFlow.Amqp.ErrorConsumer do
  @moduledoc """
  Consumer of all job with error status.
  """

  require Logger

  alias StepFlow.Amqp.ErrorConsumer
  alias StepFlow.Jobs
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
    case Jobs.get_job(job_id) do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      _ ->
        Logger.error("Job error #{inspect(payload)}")
        Status.set_job_status(job_id, :error, %{message: description})
        Workflows.notification_from_job(job_id, description)

        Basic.ack(channel, tag)
    end
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
    case Jobs.get_job(job_id) do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      _ ->
        Logger.error("Job error #{inspect(payload)}")
        Status.set_job_status(job_id, :error, %{message: description})
        Workflows.notification_from_job(job_id, description)

        Basic.ack(channel, tag)
    end
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job error #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
