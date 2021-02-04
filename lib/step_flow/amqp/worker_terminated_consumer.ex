defmodule StepFlow.Amqp.WorkerTerminatedConsumer do
  @moduledoc """
  Consumer of all worker terminations.
  """

  require Logger
  alias StepFlow.Amqp.WorkerTerminatedConsumer
  alias StepFlow.LiveWorkers
  alias StepFlow.Workflows
  alias StepFlow.Workflows.StepManager

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_terminated",
    exchange: "worker_response",
    prefetch_count: 1,
    consumer: &WorkerTerminatedConsumer.consume/4
  }

  @doc """
  Consume worker terminated message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = _payload
      ) do
    live_worker_update(job_id)
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker terminated #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end

  defp live_worker_update(job_id) do
    live_worker = LiveWorkers.get_by(%{"job_id" => job_id})

    LiveWorkers.update_live_worker(live_worker, %{
      "termination_date" => NaiveDateTime.utc_now()
    })

    Workflows.notification_from_job(job_id)
    StepManager.check_step_status(%{job_id: job_id})
    :ok
  end
end
