defmodule StepFlow.ProgressionsViewTest do
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

  test "render a Worker Definition" do
    {:ok, datetime, 0} = DateTime.from_iso8601("2020-01-31T09:48:53Z")

    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, job} =
      StepFlow.Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id
      })

    {:ok, progression} =
      StepFlow.Progressions.create_progression(%{
        job_id: job.id,
        datetime: datetime,
        docker_container_id: "unknown",
        progression: 50
      })

    assert render(StepFlow.ProgressionsView, "show.json", %{progressions: progression}) == %{
             data: %{
               id: progression.id,
               job_id: job.id,
               datetime: datetime,
               docker_container_id: "unknown",
               progression: 50
             }
           }
  end

  test "render many Worker Definitions" do
    {:ok, datetime, 0} = DateTime.from_iso8601("2020-01-31T09:48:53Z")

    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    _workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, job} =
      StepFlow.Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id
      })

    {:ok, progression} =
      StepFlow.Progressions.create_progression(%{
        job_id: job.id,
        datetime: datetime,
        docker_container_id: "unknown",
        progression: 50
      })

    assert render(StepFlow.ProgressionsView, "index.json", %{progressions: [progression]}) == %{
             data: [
               %{
                 id: progression.id,
                 job_id: job.id,
                 datetime: datetime,
                 docker_container_id: "unknown",
                 progression: 50
               }
             ]
           }
  end
end
