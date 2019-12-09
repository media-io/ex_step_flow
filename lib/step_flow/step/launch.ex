defmodule StepFlow.Step.Launch do
  @moduledoc """
  The Step launcher context.
  """
  require Logger

  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Workflows
  alias StepFlow.Step.Helpers

  def launch_step(workflow, step_name, step) do
    dates = Helpers.get_dates()

    # refresh workflow to get recent stored parameters on it
    workflow = Workflows.get_workflow!(workflow.id)

    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)
    step_mode = StepFlow.Map.get_by_key_or_atom(step, :mode, "one_for_one")
    source_paths = get_source_paths(workflow, step, dates)

    case {source_paths, step_mode} do
      {[], _} ->
        Logger.debug("job one for one path")
        Jobs.create_skipped_job(workflow, step_id, step_name)

      {source_paths, "one_for_one"} when is_list(source_paths) ->
        first_file =
          source_paths
          |> Enum.sort()
          |> List.first()

        start_job_one_for_one(
          source_paths,
          step,
          step_name,
          step_id,
          dates,
          first_file,
          workflow
        )

      {source_paths, "one_for_many"} when is_list(source_paths) ->
        Logger.debug("job one for many paths")
        start_job_one_for_many(source_paths, step, step_name, step_id, dates, workflow)

      {_, _} ->
        Jobs.create_skipped_job(workflow, step_id, step_name)
    end
  end

  defp start_job_one_for_one([], _step, _step_name, _step_id, _dates, _first_file, _workflow),
    do: {:ok, "started"}

  defp start_job_one_for_one(
         [source_path | source_paths],
         step,
         step_name,
         step_id,
         dates,
         first_file,
         workflow
       ) do
    message =
      generate_message_one_for_one(
        source_path,
        step,
        step_name,
        step_id,
        dates,
        first_file,
        workflow
      )

    case CommonEmitter.publish_json(step_name, message) do
      :ok ->
        start_job_one_for_one(source_paths, step, step_name, step_id, dates, first_file, workflow)

      _ ->
        {:error, "unable to publish message"}
    end
  end

  def get_source_paths(workflow, step, dates) do
    input_filter = Helpers.get_value_in_parameters(step, "input_filter")

    case StepFlow.Map.get_by_key_or_atom(step, :parent_ids, []) do
      [] ->
        Helpers.get_value_in_parameters(step, "source_paths")
        |> List.flatten()
        |> Helpers.templates_process(workflow, dates, [])
        |> Helpers.filter_path_list(input_filter)

      parent_ids ->
        workflow.jobs
        |> Enum.filter(fn job -> job.step_id in parent_ids end)
        |> Helpers.get_jobs_destination_paths()
        |> Helpers.filter_path_list(input_filter)
    end
  end

  def start_job_one_for_many(source_paths, step, step_name, step_id, dates, workflow) do
    message =
      generate_message_one_for_many(source_paths, step, step_name, step_id, dates, workflow)

    case CommonEmitter.publish_json(step_name, message) do
      :ok -> {:ok, "started"}
      _ -> {:error, "unable to publish message"}
    end
  end

  def generate_message_one_for_one(
        source_path,
        step,
        step_name,
        step_id,
        dates,
        first_file,
        workflow
      ) do
    destination_path_templates =
      Helpers.get_value_in_parameters_with_type(step, "destination_path", "template")

    destination_filename_templates =
      Helpers.get_value_in_parameters_with_type(step, "destination_filename", "template")

    {required_paths, destination_path} =
      build_requirements_and_destination_path(
        destination_path_templates,
        destination_filename_templates,
        workflow,
        dates,
        source_path,
        first_file
      )

    requirements =
      Helpers.get_step_requirements(workflow.jobs, step)
      |> Helpers.add_required_paths(required_paths)

    parameters =
      filter_and_pre_compile_parameters(step, workflow, dates, source_path)
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

  def generate_message_one_for_many(source_paths, step, step_name, step_id, dates, workflow) do
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

    destination_filename_templates =
      Helpers.get_value_in_parameters_with_type(step, "destination_filename", "template")

    select_input =
      case destination_filename_templates do
        [destination_filename_template] ->
          filename =
            destination_filename_template
            |> Helpers.template_process(workflow, dates, source_paths)
            |> Path.basename()

          destination_path = Helpers.get_base_directory(workflow) <> filename

          Enum.concat(select_input, [
            %{
              id: "destination_path",
              type: "string",
              value: destination_path
            }
          ])

        _ ->
          select_input
      end

    source_paths = get_source_paths(workflow, dates, step, source_paths)

    requirements =
      Helpers.get_step_requirements(workflow.jobs, step)
      |> Helpers.add_required_paths(source_paths)

    parameters =
      filter_and_pre_compile_parameters(step, workflow, dates, source_paths)
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

  def build_requirements_and_destination_path(
        [destination_path_template],
        _,
        workflow,
        dates,
        source_path,
        _first_file
      ) do
    destination_path =
      Helpers.template_process(destination_path_template, workflow, dates, source_path)

    {[], destination_path}
  end

  def build_requirements_and_destination_path(
        _,
        [destination_filename_template],
        workflow,
        dates,
        source_path,
        first_file
      ) do
    filename =
      Helpers.template_process(destination_filename_template, workflow, dates, source_path)
      |> Path.basename()

    base_directory = Helpers.get_base_directory(workflow)

    required_paths =
      if source_path != first_file do
        base_directory <> Path.basename(first_file)
      else
        []
      end

    {required_paths, base_directory <> filename}
  end

  def build_requirements_and_destination_path(_, _, workflow, _dates, source_path, first_file) do
    base_directory = Helpers.get_base_directory(workflow)

    required_paths =
      if source_path != first_file do
        base_directory <> Path.basename(first_file)
      else
        []
      end

    {required_paths, base_directory <> Path.basename(source_path)}
  end

  defp get_source_paths(workflow, dates, step, source_paths) do
    source_paths_templates =
      Helpers.get_value_in_parameters_with_type(step, "source_paths", "array_of_templates")
      |> List.flatten()

    case source_paths_templates do
      nil ->
        source_paths

      [] ->
        source_paths

      templates ->
        Enum.map(
          templates,
          fn template ->
            Helpers.template_process(template, workflow, dates, nil)
          end
        )
    end
  end

  defp filter_and_pre_compile_parameters(step, workflow, dates, source_paths) do
    StepFlow.Map.get_by_key_or_atom(step, :parameters, [])
    |> Enum.map(fn param ->
      case StepFlow.Map.get_by_key_or_atom(param, :type) do
        "template" ->
          value =
            StepFlow.Map.get_by_key_or_atom(
              param,
              :value,
              StepFlow.Map.get_by_key_or_atom(param, :default)
            )
            |> Helpers.template_process(workflow, dates, source_paths)

          %{
            id: StepFlow.Map.get_by_key_or_atom(param, :id),
            type: "string",
            value: value
          }

        _ ->
          param
      end
    end)
    |> Enum.filter(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :type) != "filter" &&
        StepFlow.Map.get_by_key_or_atom(param, :type) != "template" &&
        StepFlow.Map.get_by_key_or_atom(param, :type) != "select_input" &&
        StepFlow.Map.get_by_key_or_atom(param, :type) != "array_of_templates"
    end)
  end
end
