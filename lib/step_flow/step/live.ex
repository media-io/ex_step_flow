defmodule StepFlow.Step.Live do
  @moduledoc """
  The Live step context.
  """
  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo
  alias StepFlow.Step.Launch
  alias StepFlow.Step.LaunchParams

  def update_job_live(
        [source_path | _source_paths],
        launch_params,
        workflow,
        step
      ) do
    workflow_id = workflow.id
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    case Jobs.get_by(%{"workflow_id" => workflow_id, "step_id" => step_id}) do
      nil ->
        create_live_worker(source_path, launch_params)

      job ->
        job = Repo.preload(job, :status)

        case Status.get_last_status(job.status).state do
          :ready_to_init -> update_live_worker(launch_params, job)
          :ready_to_start -> update_live_worker(launch_params, job)
          :completed -> delete_live_worker(launch_params, job)
          _ -> {:ok, "nothing to do"}
        end
    end
  end

  defp create_live_worker(source_path, launch_params) do
    message = Launch.generate_message_one_for_one(source_path, launch_params)

    message =
      Map.put(
        message,
        :parameters,
        message.parameters ++ [%{id: "action", type: "string", value: "create"}]
      )

    message = filter_message(message)

    case CommonEmitter.publish_json(
           "job_worker_manager",
           LaunchParams.get_step_id(launch_params),
           message
         ) do
      :ok -> {:ok, "started"}
      _ -> {:error, "unable to publish message"}
    end
  end

  defp update_live_worker(launch_params, job) do
    generate_message(job)
    |> publish_message(launch_params)
  end

  defp delete_live_worker(launch_params, job) do
    message = generate_message(job)
    message = filter_message(message)

    case CommonEmitter.publish_json(
           "job_worker_manager",
           LaunchParams.get_step_id(launch_params),
           message
         ) do
      :ok -> {:ok, "deleted"}
      _ -> {:error, "unable to publish message"}
    end
  end

  def generate_message(job) do
    message = Jobs.get_message(job)

    action_parameter =
      job.status
      |> Status.get_last_status()
      |> Status.get_action_parameter()

    Map.put(message, :parameters, message.parameters ++ action_parameter)
  end

  defp filter_message(message) do
    Map.put(
      message,
      :parameters,
      Enum.filter(message.parameters, fn x ->
        Enum.member?(
          ["step_id", "action", "namespace", "worker", "ports", "direct_messaging_queue"],
          x["id"]
        )
      end)
    )
  end

  defp publish_message(message, launch_params) do
    case CommonEmitter.publish_json(
           LaunchParams.get_step_parameter(launch_params, "direct_messaging_queue").value,
           LaunchParams.get_step_id(launch_params),
           message
         ) do
      :ok -> {:ok, "started"}
      _ -> {:error, "unable to publish message"}
    end
  end
end
