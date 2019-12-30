defmodule StepFlow.Amqp.CompletedConsumer do
  @moduledoc """
  Consumer of all job with completed status.
  """

  require Logger
  alias StepFlow.Amqp.CompletedConsumer
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows
  alias StepFlow.Workflows.StepManager

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_completed",
    consumer: &CompletedConsumer.consume/4
  }

  @doc """
  Consume messages with completed topic, update Job status and continue the workflow.
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
    job = Jobs.get_job!(job_id)

    workflow =
      job
      |> Map.get(:workflow_id)
      |> Workflows.get_workflow!()

    case StepFlow.Map.get_by_key_or_atom(payload, "destination_paths") do
      nil ->
        nil

      destination_paths ->
        job_parameters =
          job.parameters ++
            [
              %{
                id: "destination_paths",
                type: "array_of_strings",
                value: destination_paths
              }
            ]

        Jobs.update_job(job, %{parameters: job_parameters})
    end

    case StepFlow.Map.get_by_key_or_atom(payload, "parameters") do
      nil ->
        nil

      parameters ->
        parameters = workflow.parameters ++ parameters
        Workflows.update_workflow(workflow, %{parameters: parameters})
    end

    Status.set_job_status(job_id, status)
    Workflows.notification_from_job(job_id)
    StepManager.check_step_status(%{job_id: job_id})
    Basic.ack(channel, tag)
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job completed #{inspect(payload)}")
    Basic.ack(channel, tag)
  end
end
