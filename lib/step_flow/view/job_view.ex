defmodule StepFlow.JobView do
  use StepFlow, :view
  alias StepFlow.JobView

  def render("index.json", %{jobs: %{data: jobs, total: total}}) do
    %{
      data: render_many(jobs, JobView, "job.json"),
      total: total
    }
  end

  def render("show.json", %{job: job}) do
    %{data: render_one(job, JobView, "job.json")}
  end

  def render("job.json", %{job: job}) do
    if is_tuple(job) do
      case job do
        {:error, changeset} ->
          %{errors: changeset |> StepFlow.ChangesetView.translate_errors()}

        _ ->
          %{errors: ["unknown error"]}
      end
    else
      status =
        if is_list(job.status) do
          render_many(job.status, StepFlow.StatusView, "state.json")
        else
          []
        end

      progressions =
        if is_list(job.progressions) do
          render_many(job.progressions, StepFlow.ProgressionsView, "progression.json")
        else
          []
        end

      %{
        id: job.id,
        workflow_id: job.workflow_id,
        name: job.name,
        step_id: job.step_id,
        params: job.parameters,
        progressions: progressions,
        status: status,
        inserted_at: job.inserted_at,
        updated_at: job.updated_at
      }
    end
  end
end
