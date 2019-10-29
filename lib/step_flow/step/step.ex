defmodule StepFlow.Step do
  @moduledoc """
  The Step context.
  """

  require Logger

  alias StepFlow.Artifacts
  alias StepFlow.Jobs
  alias StepFlow.Repo
  alias StepFlow.Step.Launch
  alias StepFlow.Workflows.Workflow

  def start_next(%Workflow{id: workflow_id} = workflow) do
    workflow = Repo.preload(workflow, :jobs, force: true)

    step_index =
      Enum.map(workflow.jobs, fn job -> (job.step_id |> Integer.to_string()) <> job.name end)
      |> Enum.uniq()
      |> length

    steps = StepFlow.Map.get_by_key_or_atom(workflow, :steps)

    case Enum.at(steps, step_index) do
      nil ->
        set_artifacts(workflow)
        Logger.warn("#{__MODULE__}: workflow #{workflow_id} is completed")
        {:ok, "completed"}

      step ->
        Logger.warn(
          "#{__MODULE__}: start to process step #{step["name"]} (index #{step_index}) for workflow #{
            workflow_id
          }"
        )

        step_name = StepFlow.Map.get_by_key_or_atom(step, :name)
        status = Launch.launch_step(workflow, step_name, step)

        Logger.info("#{step_name}: #{inspect(status)}")
        topic = "update_workflow_" <> Integer.to_string(workflow_id)

        StepFlow.Notification.send(topic, %{workflow_id: workflow.id})

        case status do
          {:ok, "skipped"} -> start_next(workflow)
          {:ok, "completed"} -> start_next(workflow)
          _ -> status
        end
    end
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
end
