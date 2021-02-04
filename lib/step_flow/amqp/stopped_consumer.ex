defmodule StepFlow.Amqp.StoppedConsumer do
  @moduledoc """
  Consumer of all job with stopped status.
  """

  require Logger

  alias StepFlow.{
    Amqp.StoppedConsumer,
    Jobs,
    Jobs.Status,
    LiveWorkers,
    Step.Live,
    Workflows,
    Workflows.StepManager
  }

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_stopped",
    exchange: "job_response",
    prefetch_count: 1,
    consumer: &StoppedConsumer.consume/4
  }

  @doc """
  Consume messages with stopped topic, update Job status and continue the workflow.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id,
          "status" => status
        } = payload
      ) do
    case Jobs.get_job(job_id) do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      job ->
        workflow =
          job
          |> Map.get(:workflow_id)
          |> Workflows.get_workflow!()

        Status.set_job_status(job_id, status)
        Workflows.notification_from_job(job_id)
        StepManager.check_step_status(%{job_id: job_id})

        Basic.ack(channel, tag)
    end
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job stopped #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
