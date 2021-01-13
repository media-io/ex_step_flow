defmodule StepFlow.UpdatesViewTest do
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
    schema_version: "1.8",
    identifier: "id",
    version_major: 6,
    version_minor: 5,
    version_micro: 4,
    reference: "some id",
    steps: [],
    rights: [
      %{
        action: "create",
        groups: ["administrator"]
      }
    ]
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

    {:ok, update} =
      StepFlow.Updates.create_update(%{
        job_id: job.id,
        datetime: datetime,
        parameters: [%{test: "toto"}]
      })

    assert render(StepFlow.UpdatesView, "show.json", %{updates: update}) == %{
             data: %{
               id: update.id,
               job_id: job.id,
               datetime: datetime,
               parameters: [%{test: "toto"}]
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

    {:ok, update} =
      StepFlow.Updates.create_update(%{
        job_id: job.id,
        datetime: datetime,
        parameters: [%{test: "toto"}]
      })

    assert render(StepFlow.UpdatesView, "index.json", %{updates: [update]}) == %{
             data: [
               %{
                 id: update.id,
                 job_id: job.id,
                 datetime: datetime,
                 parameters: [%{test: "toto"}]
               }
             ]
           }
  end
end
