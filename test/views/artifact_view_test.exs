defmodule StepFlow.ArtifactViewTest do
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

  test "render an Artifact" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, artifact} =
      StepFlow.Artifacts.create_artifact(%{resources: %{}, workflow_id: workflow.id})

    assert render(StepFlow.ArtifactView, "show.json", %{artifact: artifact}) == %{
             data: %{
               id: artifact.id,
               inserted_at: artifact.inserted_at,
               resources: %{}
             }
           }
  end

  test "render many Artifacts" do
    {:ok, workflow} = StepFlow.Workflows.create_workflow(@workflow)
    workflow = StepFlow.Repo.preload(workflow, [:artifacts, :jobs])

    {:ok, artifact} =
      StepFlow.Artifacts.create_artifact(%{resources: %{}, workflow_id: workflow.id})

    assert render(StepFlow.ArtifactView, "index.json", %{artifact: [artifact]}) == %{
             data: [
               %{
                 id: artifact.id,
                 inserted_at: artifact.inserted_at,
                 resources: %{}
               }
             ]
           }
  end
end
