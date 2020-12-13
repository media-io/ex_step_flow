defmodule StepFlow.Amqp.QueueNotFoundConsumer do
  @moduledoc """
  Consumer of all job not finding their queue.
  """

  require Logger

  alias StepFlow.Amqp.QueueNotFoundConsumer
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_queue_not_found",
    prefetch_count: 1,
    consumer: &QueueNotFoundConsumer.consume/4
  }

  @doc """
  Consume message with queue not found topic, update Job in error and send a notification.
  """
  def consume(channel, tag, _redelivered, %{"job_id" => job_id} = payload) do
    case Jobs.get_job(job_id) do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      _ ->
        IO.inspect("coucou")
        description = "The queue for the job was not found."
        Logger.error("Job error #{inspect(payload)}")
        Status.set_job_status(job_id, :error, %{message: description})
        Workflows.notification_from_job(job_id, description)

        Basic.ack(channel, tag)
    end
  end

  def consume(channel, tag, _redelivered, payload) do
    IO.inspect("coucou")
    Logger.error("Job error #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
