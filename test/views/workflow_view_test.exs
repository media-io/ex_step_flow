defmodule StepFlow.WorkflowViewTest do
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

  test "render a Workflow" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    assert render(StepFlow.WorkflowView, "show.json", %{workflow: workflow}) == %{
             data: %{
               id: workflow.id,
               artifacts: [],
               created_at: workflow.inserted_at,
               jobs: [],
               tags: [],
               identifier: "id",
               version_major: 6,
               version_minor: 5,
               version_micro: 4,
               reference: "some id",
               parameters: [],
               steps: []
             }
           }
  end

  test "render many Workflows" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    assert render(StepFlow.WorkflowView, "index.json", %{workflows: %{data: [workflow], total: 1}}) ==
             %{
               data: [
                 %{
                   id: workflow.id,
                   artifacts: [],
                   created_at: workflow.inserted_at,
                   jobs: [],
                   tags: [],
                   identifier: "id",
                   version_major: 6,
                   version_minor: 5,
                   version_micro: 4,
                   reference: "some id",
                   parameters: [],
                   steps: []
                 }
               ],
               total: 1
             }
  end
end
