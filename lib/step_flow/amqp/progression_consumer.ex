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
    consumer: &ProgressionConsumer.consume/4
  }
  
  @doc """
  Consumme message with job progression and save it in database
  """
  def consume(
      channel, 
      tag, 
      _redelivered, 
      %{
        "job_id" => job_id
      } = payload
    ) do
    _job = Jobs.get_job!(job_id)

    Progressions.create_progression(payload)
    Workflows.notification_from_job(job_id)
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job completed #{inspect(payload)}")
    Basic.ack(channel, tag)
  end
end
