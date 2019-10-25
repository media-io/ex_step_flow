defmodule StepFlow.Step.Launch do
  @moduledoc """
  The Step launcher context.
  """
  require Logger

  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Step.Helpers

  def launch_step(workflow, step_name, step) do
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)
    step_mode = StepFlow.Map.get_by_key_or_atom(step, :mode, "one_for_one")
    source_paths = get_source_paths(workflow, step)

    case {source_paths, step_mode} do
      {[], _} ->
        Logger.debug("job one for one path")
        Jobs.create_skipped_job(workflow, step_id, step_name)

      {source_paths, "one_for_one"} when is_list(source_paths) ->
        first_file =
          source_paths
          |> Enum.sort()
          |> List.first()

        start_job_one_for_one(source_paths, step, step_name, step_id, first_file, workflow)

      {source_paths, "one_for_many"} when is_list(source_paths) ->
        Logger.debug("job one for many paths")
        start_job_one_for_many(source_paths, step, step_name, step_id, workflow)

      {_, _} ->
        Jobs.create_skipped_job(workflow, step_id, step_name)
    end
  end

  defp start_job_one_for_one([], _step, _step_name, _step_id, _first_file, _workflow),
    do: {:ok, "started"}

  defp start_job_one_for_one(
         [source_path | source_paths],
         step,
         step_name,
         step_id,
         first_file,
         workflow
       ) do
    message =
      generate_message_one_for_one(source_path, step, step_name, step_id, first_file, workflow)

    case CommonEmitter.publish_json(step_name, message) do
      :ok -> start_job_one_for_one(source_paths, step, step_name, step_id, first_file, workflow)
      _ -> {:error, "unable to publish message"}
    end
  end

  def get_source_paths(workflow, step) do
    input_filter = Helpers.get_value_in_parameters(step, "input_filter")

    case StepFlow.Map.get_by_key_or_atom(step, :parent_ids, []) do
      [] ->
        Helpers.get_value_in_parameters(step, "source_paths")
        |> List.flatten()
        |> Helpers.filter_path_list(input_filter)

      parent_ids ->
        workflow.jobs
        |> Enum.filter(fn job -> job.step_id in parent_ids end)
        |> Helpers.get_jobs_destination_paths()
        |> Helpers.filter_path_list(input_filter)
    end
  end

  def start_job_one_for_many(source_paths, step, step_name, step_id, workflow) do
    message = generate_message_one_for_many(source_paths, step, step_name, step_id, workflow)

    case CommonEmitter.publish_json(step_name, message) do
      :ok -> {:ok, "started"}
      _ -> {:error, "unable to publish message"}
    end
  end

  def generate_message_one_for_one(source_path, step, step_name, step_id, first_file, workflow) do
    work_directory =
      System.get_env("WORK_DIR") || Application.get_env(:ex_backend, :work_dir) || ""

    destination_filename_templates =
      StepFlow.Map.get_by_key_or_atom(step, :parameters, [])
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "destination_filename" &&
          StepFlow.Map.get_by_key_or_atom(param, :type) == "template"
      end)
      |> Enum.map(fn param ->
        StepFlow.Map.get_by_key_or_atom(
          param,
          :value,
          StepFlow.Map.get_by_key_or_atom(param, :default)
        )
      end)

    filename =
      case destination_filename_templates do
        [destination_filename_template] ->
          destination_filename_template
          |> String.replace("{source_path}", "<%= source_path %>")
          |> String.replace("{workflow_id}", "<%= workflow_id %>")
          |> String.replace("{work_directory}", "<%= work_directory %>")
          |> EEx.eval_string(
            workflow_id: workflow.id,
            work_directory: work_directory,
            source_path: source_path
          )
          |> Path.basename()

        _ ->
          Path.basename(source_path)
      end

    destination_path = work_directory <> "/" <> Integer.to_string(workflow.id) <> "/" <> filename

    required_paths =
      if source_path != first_file do
        Path.dirname(destination_path) <> "/" <> Path.basename(first_file)
      else
        []
      end

    requirements =
      Helpers.get_step_requirements(workflow.jobs, step)
      |> Helpers.add_required_paths(required_paths)

    parameters =
      StepFlow.Map.get_by_key_or_atom(step, :parameters, [])
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :type) != "filter" &&
          StepFlow.Map.get_by_key_or_atom(param, :type) != "template" &&
          StepFlow.Map.get_by_key_or_atom(param, :type) != "select_input"
      end)
      |> Enum.concat([
        %{
          "id" => "source_path",
          "type" => "string",
          "value" => source_path
        },
        %{
          "id" => "destination_path",
          "type" => "string",
          "value" => destination_path
        },
        %{
          "id" => "requirements",
          "type" => "requirements",
          "value" => requirements
        }
      ])

    job_params = %{
      name: step_name,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: parameters
    }

    {:ok, job} = Jobs.create_job(job_params)

    Jobs.get_message(job)
  end

  def generate_message_one_for_many(source_paths, step, step_name, step_id, workflow) do
    requirements =
      Helpers.get_step_requirements(workflow.jobs, step)
      |> Helpers.add_required_paths(source_paths)

    select_input =
      StepFlow.Map.get_by_key_or_atom(step, :parameters, [])
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :type) == "select_input"
      end)
      |> Enum.map(fn param ->
        id = StepFlow.Map.get_by_key_or_atom(param, :id)
        value = StepFlow.Map.get_by_key_or_atom(param, :value)
        Logger.warn("source paths: #{inspect(source_paths)} // value: #{inspect(value)}")

        path =
          Helpers.filter_path_list(source_paths, [value])
          |> List.first()

        %{
          id: id,
          type: "string",
          value: path
        }
      end)

    parameters =
      StepFlow.Map.get_by_key_or_atom(step, :parameters, [])
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :type) != "filter" &&
          StepFlow.Map.get_by_key_or_atom(param, :type) != "template" &&
          StepFlow.Map.get_by_key_or_atom(param, :type) != "select_input"
      end)
      |> Enum.concat(select_input)
      |> Enum.concat([
        %{
          "id" => "source_paths",
          "type" => "array_of_strings",
          "value" => source_paths
        },
        %{
          "id" => "requirements",
          "type" => "requirements",
          "value" => requirements
        }
      ])

    job_params = %{
      name: step_name,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: parameters
    }

    {:ok, job} = Jobs.create_job(job_params)

    Jobs.get_message(job)
  end
end
