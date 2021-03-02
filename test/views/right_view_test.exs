defmodule StepFlow.RightViewTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
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

  test "render an Right" do
    {:ok, %{rights: [right]}} = StepFlow.Workflows.create_workflow(@workflow)

    assert render(StepFlow.RightView, "show.json", %{right: right}) == %{
             data: %{
               id: right.id,
               action: right.action,
               groups: right.groups,
               inserted_at: right.inserted_at
             }
           }
  end

  test "render many Rights" do
    {:ok, %{rights: [right]}} = StepFlow.Workflows.create_workflow(@workflow)

    assert render(StepFlow.RightView, "index.json", %{rights: [right]}) == %{
             data: [
               %{
                 id: right.id,
                 action: right.action,
                 groups: right.groups,
                 inserted_at: right.inserted_at
               }
             ]
           }
  end
end
