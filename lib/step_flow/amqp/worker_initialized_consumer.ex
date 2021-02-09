defmodule StepFlow.Amqp.WorkerInitializedConsumer do
  @moduledoc """
  Consumer of all worker inits.
  """

  import Ecto.Query, warn: false

  require Logger
  alias StepFlow.Amqp.WorkerInitializedConsumer
  alias StepFlow.Jobs.Job
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo
  alias StepFlow.Step.Live
  alias StepFlow.Workflows
  alias StepFlow.Workflows.StepManager


  use StepFlow.Amqp.CommonConsumer, %{
    queue: "worker_initialized",
    exchange: "worker_response",
    prefetch_count: 1,
    consumer: &WorkerInitializedConsumer.consume/4
  }

  @doc """
  Consume worker initialized message.
  """
  def consume(
        channel,
        tag,
        _redelivered,
        %{
          "job_id" => job_id
        } = _payload
      ) do
    {:ok, _} = Status.set_job_status(job_id, "ready_to_start")
    query = from(job in Job, select: job.id)
    stream = Repo.stream(query)
    Repo.transaction(fn() ->
      Enum.to_list(stream)
    end)
    :timer.sleep(5000)
    Workflows.notification_from_job(job_id)
    StepManager.check_step_status(%{job_id: job_id})
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Worker initialized #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end
end
