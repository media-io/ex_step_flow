defmodule StepFlow.JobViewTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  setup do
    # Explicitly get a connection before each test
    Sandbox.checkout(StepFlow.Repo)
  end

  @workflow %{
    identifier: "id",
    version_major: 6,
    version_minor: 5,
    version_micro: 4,
    reference: "some id",
    steps: []
  }

  test "render a Job" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, job} =
      StepFlow.Jobs.create_job(%{name: "job_test", step_id: 0, workflow_id: workflow.id})

    assert render(StepFlow.JobView, "show.json", %{job: job}) == %{
             data: %{
               id: job.id,
               inserted_at: job.inserted_at,
               name: "job_test",
               params: [],
               progressions: [],
               status: [],
               step_id: 0,
               updated_at: job.updated_at,
               workflow_id: workflow.id
             }
           }
  end

  test "render many Jobs" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, job} =
      StepFlow.Jobs.create_job(%{name: "job_test", step_id: 0, workflow_id: workflow.id})

    assert render(StepFlow.JobView, "index.json", %{jobs: %{data: [job], total: 1}}) == %{
             data: [
               %{
                 id: job.id,
                 inserted_at: job.inserted_at,
                 name: "job_test",
                 params: [],
                 progressions: [],
                 status: [],
                 step_id: 0,
                 updated_at: job.updated_at,
                 workflow_id: workflow.id
               }
             ],
             total: 1
           }
  end
end
