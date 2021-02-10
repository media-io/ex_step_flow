defmodule StepFlow.Amqp.ProgressionConsumer do
  @moduledoc """
  Consumer of all progression jobs.
  """

  require Logger
  alias StepFlow.Amqp.ProgressionConsumer
  alias StepFlow.Jobs
  alias StepFlow.Progressions
  alias StepFlow.Workflows

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_progression",
    exchange: "job_response",
    prefetch_count: 1,
    consumer: &ProgressionConsumer.consume/4
  }

  @doc """
  Consume message with job progression and save it in database.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = payload
      ) do
    case Jobs.get_job(job_id) do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      _ ->
        Progressions.create_progression(payload)
        Workflows.notification_from_job(job_id)
        Basic.ack(channel, tag)
    end
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job progression #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
