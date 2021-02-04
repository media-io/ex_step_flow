defmodule StepFlow.Amqp.CompletedConsumer do
  @moduledoc """
  Consumer of all job with completed status.
  """

  require Logger

  alias StepFlow.{
    Amqp.CompletedConsumer,
    Jobs,
    Jobs.Status,
    LiveWorkers,
    Step.Live,
    Workflows,
    Workflows.StepManager
  }

  use StepFlow.Amqp.CommonConsumer, %{
    queue: "job_completed",
    exchange: "job_response",
    prefetch_count: 1,
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
    case Jobs.get_job(job_id) do
      nil ->
        Basic.reject(channel, tag, requeue: false)

      job ->
        if job.is_live do
          case live_worker_update(job_id, payload) do
            :ok ->
              StepManager.check_step_status(%{job_id: job_id})
              Basic.ack(channel, tag)

            :error ->
              Basic.reject(channel, tag, requeue: true)
          end
        else
          workflow =
            job
            |> Map.get(:workflow_id)
            |> Workflows.get_workflow!()

          set_generated_destination_paths(payload, job)
          set_output_parameters(payload, workflow)
          Status.set_job_status(job_id, status)
          Workflows.notification_from_job(job_id)
          StepManager.check_step_status(%{job_id: job_id})
          Basic.ack(channel, tag)
        end
    end
  end

  def consume(channel, tag, _redelivered, payload) do
    Logger.error("Job completed #{inspect(payload)}")
    Basic.reject(channel, tag, requeue: false)
  end

  defp set_generated_destination_paths(payload, job) do
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
  end

  defp set_output_parameters(payload, workflow) do
    case StepFlow.Map.get_by_key_or_atom(payload, "parameters") do
      nil ->
        nil

      parameters ->
        parameters = workflow.parameters ++ parameters
        Workflows.update_workflow(workflow, %{parameters: parameters})
    end
  end

  defp live_worker_update(job_id, payload) do
    live_worker = LiveWorkers.get_by(%{"job_id" => job_id})

    case live_worker do
      nil ->
        live_worker_creation(job_id, payload)

      _ ->
        case live_worker.termination_date do
          nil ->
            :error

          _ ->
            Status.set_job_status(job_id, "completed")
            Workflows.notification_from_job(job_id)
            :ok
        end
    end
  end

  defp live_worker_creation(job_id, payload) do
    instance_id =
      StepFlow.Map.get_by_key_or_atom(payload, :parameters)
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "instance_id"
      end)
      |> List.first()
      |> StepFlow.Map.get_by_key_or_atom(:value)

    host_ip =
      StepFlow.Map.get_by_key_or_atom(payload, :parameters)
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "host_ip"
      end)
      |> List.first()
      |> StepFlow.Map.get_by_key_or_atom(:value)

    ports =
      StepFlow.Map.get_by_key_or_atom(payload, :parameters)
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "ports"
      end)
      |> List.first()
      |> StepFlow.Map.get_by_key_or_atom(:value)

    direct_messaging_queue_name =
      StepFlow.Map.get_by_key_or_atom(payload, :parameters)
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "direct_messaging_queue_name"
      end)
      |> List.first()
      |> StepFlow.Map.get_by_key_or_atom(:value)

    LiveWorkers.create_live_worker(%{
      job_id: job_id,
      instance_id: instance_id,
      direct_messaging_queue_name: direct_messaging_queue_name,
      ips: [host_ip],
      ports: ports
    })

    :ok
  end
end
