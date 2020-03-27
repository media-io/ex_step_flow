defmodule StepFlow.Step do
  @moduledoc """
  The Step context.
  """

  require Logger

  alias StepFlow.Artifacts
  alias StepFlow.Jobs
  alias StepFlow.Repo
  alias StepFlow.Step.Launch
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow

  def start_next(%Workflow{id: workflow_id} = workflow) do
    workflow = Repo.preload(workflow, :jobs, force: true)

    jobs = Repo.preload(workflow.jobs, :status)

    steps =
      StepFlow.Map.get_by_key_or_atom(workflow, :steps)
      |> Workflows.get_step_status(jobs)

    {is_completed_workflow, steps_to_start} = get_steps_to_start(steps)

    steps_to_start =
      case {steps_to_start, jobs} do
        {[], []} ->
          case List.first(steps) do
            nil ->
              Logger.warn("#{__MODULE__}: empty workflow #{workflow_id} is completed")
              {:completed_workflow, []}

            step ->
              {:ok, [step]}
          end

        {[], _} ->
          {:completed_workflow, []}

        {list, _} ->
          {:ok, list}
      end

    results = start_steps(steps_to_start, workflow)

    get_final_status(workflow, is_completed_workflow, Enum.uniq(results) |> Enum.sort())
  end

  def skip_step(workflow, step) do
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)
    step_name = StepFlow.Map.get_by_key_or_atom(step, :name)

    Repo.preload(workflow, :jobs, force: true)
    |> Jobs.create_skipped_job(step_id, step_name)
  end

  def skip_step_jobs(workflow, step) do
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)
    step_name = StepFlow.Map.get_by_key_or_atom(step, :name)

    Repo.preload(workflow, :jobs, force: true)
    |> Jobs.skip_jobs(step_id, step_name)
  end

  defp set_artifacts(workflow) do
    resources = %{}

    params = %{
      resources: resources,
      workflow_id: workflow.id
    }

    Artifacts.create_artifact(params)
  end

  defp get_steps_to_start(steps), do: iter_get_steps_to_start(steps, steps)

  defp iter_get_steps_to_start(steps, all_steps, completed \\ true, result \\ [])
  defp iter_get_steps_to_start([], _all_steps, completed, result), do: {completed, result}

  defp iter_get_steps_to_start([step | steps], all_steps, completed, result) do
    completed =
      if step.status in [:completed, :skipped] do
        completed
      else
        false
      end

    result =
      if step.status == :queued do
        if Map.has_key?(step, :required_to_start) do
          count_not_completed =
            Enum.filter(all_steps, fn s -> s.id in step.required_to_start end)
            |> Enum.map(fn s -> s.status end)
            |> Enum.filter(fn s -> s != :completed and s != :skipped end)
            |> length

          if count_not_completed == 0 do
            List.insert_at(result, -1, step)
          else
            result
          end
        else
          List.insert_at(result, -1, step)
        end
      else
        result
      end

    iter_get_steps_to_start(steps, all_steps, completed, result)
  end

  defp start_steps({:completed_workflow, _}, _workflow), do: [:completed_workflow]

  defp start_steps({:ok, steps}, workflow) do
    for step <- steps do
      step_name = StepFlow.Map.get_by_key_or_atom(step, :name)
      step_id = StepFlow.Map.get_by_key_or_atom(step, :id)
      Logger.warn(
        "#{__MODULE__}: start to process step #{step_name} (index #{step_id}) for workflow #{
          workflow.id
        }"
      )

      {result, status} = Launch.launch_step(workflow, step_name, step)

      Logger.info("#{step_name}: #{inspect({result, status})}")
      topic = "update_workflow_" <> Integer.to_string(workflow.id)

      StepFlow.Notification.send(topic, %{workflow_id: workflow.id})

      status
    end
  end

  defp get_final_status(_workflow, _is_completed_workflow, ["started"]), do: {:ok, "started"}
  defp get_final_status(_workflow, _is_completed_workflow, ["created"]), do: {:ok, "started"}

  defp get_final_status(_workflow, _is_completed_workflow, ["created", "started"]),
    do: {:ok, "started"}

  defp get_final_status(workflow, _is_completed_workflow, ["skipped"]), do: start_next(workflow)
  defp get_final_status(workflow, _is_completed_workflow, ["completed"]), do: start_next(workflow)

  defp get_final_status(workflow, true, [:completed_workflow]) do
    set_artifacts(workflow)
    Logger.warn("#{__MODULE__}: workflow #{workflow.id} is completed")
    {:ok, "completed"}
  end

  defp get_final_status(_workflow, _is_completed_workflow, _states), do: {:ok, "still_processing"}
end
