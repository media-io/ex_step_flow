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

  def create_job_live([source_path | _source_paths], launch_params) do
    message = generate_message_live(source_path, launch_params)

    message =
      Map.put(
        message,
        :parameters,
        message.parameters ++ [%{"id" => "action", "type" => "string", "value" => "create"}]
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

  def update_job_live(job_id) do
    job = Repo.preload(Jobs.get_job(job_id), [:status, :updates])
    step_id = job.step_id

    case Status.get_last_status(job.status).state do
      :ready_to_init -> update_live_worker(step_id, job)
      :ready_to_start -> update_live_worker(step_id, job)
      :update -> update_live_worker(step_id, job)
      :completed -> delete_live_worker(step_id, job)
      _ -> {:ok, "nothing to do"}
    end
  end

  defp update_live_worker(step_id, job) do
    generate_message(job)
    |> publish_message(step_id)
  end

  defp delete_live_worker(step_id, job) do
    message = generate_message(job)
    message = filter_message(message)

    case CommonEmitter.publish_json(
           "job_worker_manager",
           step_id,
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
          ["step_id", "action", "namespace", "worker", "ports", "direct_messaging_queue_name"],
          StepFlow.Map.get_by_key_or_atom(x, :id)
        )
      end)
    )
  end

  defp publish_message(message, step_id) do
    case CommonEmitter.publish_json(
           "direct_messaging_" <> get_direct_messaging_queue(message),
           step_id,
           message
         ) do
      :ok -> {:ok, "started"}
      _ -> {:error, "unable to publish message"}
    end
  end

  defp get_direct_messaging_queue(message) do
    StepFlow.Map.get_by_key_or_atom(message, :parameters)
    |> Enum.filter(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :id) == "direct_messaging_queue_name"
    end)
    |> List.first()
    |> StepFlow.Map.get_by_key_or_atom(:value)
  end

  def generate_message_live(
        source_path,
        launch_params
      ) do
    parameters =
      Launch.generate_job_parameters_one_for_one(
        source_path,
        launch_params
      )

    job_params = %{
      name: LaunchParams.get_step_name(launch_params),
      step_id: LaunchParams.get_step_id(launch_params),
      is_live: true,
      workflow_id: launch_params.workflow.id,
      parameters: parameters
    }

    {:ok, job} = Jobs.create_job(job_params)

    Jobs.get_message(job)
  end
end
