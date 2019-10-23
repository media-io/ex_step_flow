defmodule StepFlow.Step.Launch do
  @moduledoc """
  The Step launcher context.
  """

  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Step.Helpers

  def launch_step(workflow, step_name, step) do
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)
    input_filter = Helpers.get_value_in_parameters(step, "input_filter")

    source_paths =
      case StepFlow.Map.get_by_key_or_atom(step, :parent_ids, []) do
        [] ->
          Helpers.get_value_in_parameters(step, "source_paths")
          |> Helpers.filter_path_list(input_filter)

        parent_ids ->
          workflow.jobs
          |> Enum.filter(fn job -> job.step_id in parent_ids end)
          |> Helpers.get_jobs_destination_paths()
          |> Helpers.filter_path_list(input_filter)
      end

    case source_paths do
      [] ->
        Jobs.create_skipped_job(workflow, step_id, step_name)

      _ ->
        first_file =
          source_paths
          |> Enum.sort()
          |> List.first()

        start_job(source_paths, step, step_name, step_id, first_file, workflow)
    end
  end

  defp start_job([], _step, _step_name, _step_id, _first_file, _workflow), do: {:ok, "started"}

  defp start_job([source_path | source_paths], step, step_name, step_id, first_file, workflow) do
    work_directory =
      System.get_env("WORK_DIR") || Application.get_env(:ex_backend, :work_dir) || ""

    filename = Path.basename(source_path)

    dst_path = work_directory <> "/" <> Integer.to_string(workflow.id) <> "/" <> filename

    required_paths =
      if source_path != first_file do
        (Path.dirname(dst_path) <> "/" <> Path.basename(first_file))
      else
        []
      end

    requirements =
      Helpers.get_step_requirements(workflow.jobs, step)
      |> Helpers.add_required_paths(required_paths)

    parameters =
      StepFlow.Map.get_by_key_or_atom(step, :parameters, []) ++
        [
          %{
            "id" => "source_path",
            "type" => "string",
            "value" => source_path
          },
          %{
            "id" => "destination_path",
            "type" => "string",
            "value" => dst_path
          },
          %{
            "id" => "requirements",
            "type" => "requirements",
            "value" => requirements
          }
        ]

    job_params = %{
      name: step_name,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: parameters
    }

    {:ok, job} = Jobs.create_job(job_params)

    message = Jobs.get_message(job)

    case CommonEmitter.publish_json(step_name, message) do
      :ok -> start_job(source_paths, step, step_name, step_id, first_file, workflow)
      _ -> {:error, "unable to publish message"}
    end
  end
end
