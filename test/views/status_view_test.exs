defmodule StepFlow.StatusViewTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs.Status

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
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, job} =
      StepFlow.Jobs.create_job(%{name: "job_test", step_id: 0, workflow_id: workflow.id})

    {:ok, status} =
      %Status{}
      |> Status.changeset(%{state: :completed, job_id: job.id})
      |> StepFlow.Repo.insert()

    assert render(StepFlow.StatusView, "show.json", %{status: status}) == %{
             data: %{
               id: status.id,
               description: %{},
               inserted_at: status.inserted_at,
               state: :completed
             }
           }
  end

  test "render many Worker Definitions" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, job} =
      StepFlow.Jobs.create_job(%{name: "job_test", step_id: 0, workflow_id: workflow.id})

    {:ok, status} =
      %Status{}
      |> Status.changeset(%{state: :completed, job_id: job.id})
      |> StepFlow.Repo.insert()

    assert render(StepFlow.StatusView, "index.json", %{status: [status]}) == %{
             data: [
               %{
                 id: status.id,
                 description: %{},
                 inserted_at: status.inserted_at,
                 state: :completed
               }
             ]
           }
  end
end
