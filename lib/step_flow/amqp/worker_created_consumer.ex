defmodule StepFlow.Amqp.WorkerCreatedConsumer do
  @moduledoc """
  Consumer of all worker creations.
  """

  require Logger
  alias StepFlow.Amqp.WorkerCreatedConsumer
  alias StepFlow.Jobs.Status
  alias StepFlow.Step.Live

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_created",
    prefetch_count: 1,
    consumer: &WorkerCreatedConsumer.consume/4
  }

  @doc """
  Consume worker created message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "direct_messaging_queue_name" => direct_messaging_queue_name
        } = payload
      ) do
    job =
      StepFlow.Jobs.list_jobs(%{
        "direct_messaging_queue_name" => direct_messaging_queue_name
      })
      |> Map.get(:data)
      |> List.first()

    Logger.debug("Worker Creation job search result: #{inspect(job)}")

    case job do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      _ ->
        job_id = job.id
        Status.set_job_status(job_id, "ready_to_init")
        Live.update_job_live(job_id)
        Basic.ack(channel, tag)
    end
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker creation #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
