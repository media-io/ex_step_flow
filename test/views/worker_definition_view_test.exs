defmodule StepFlow.WorkerDefinitionViewTest do
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

  @worker_definition %{
    queue_name: "my_queue",
    label: "My Worker",
    version: "1.2.3",
    short_description: "short description",
    description: "long description"
  }

  test "render a Worker Definition" do
    {:ok, worker_definition} =
      StepFlow.WorkerDefinitions.create_worker_definition(@worker_definition)

    assert render(StepFlow.WorkerDefinitionView, "show.json", %{
             worker_definition: worker_definition
           }) == %{
             data: %{
               id: worker_definition.id,
               created_at: worker_definition.inserted_at,
               description: "long description",
               label: "My Worker",
               parameters: %{},
               queue_name: "my_queue",
               short_description: "short description",
               version: "1.2.3"
             }
           }
  end

  test "render many Worker Definitions" do
    {:ok, worker_definition} =
      StepFlow.WorkerDefinitions.create_worker_definition(@worker_definition)

    assert render(StepFlow.WorkerDefinitionView, "index.json", %{
             worker_definitions: %{data: [worker_definition], total: 1}
           }) == %{
             data: [
               %{
                 id: worker_definition.id,
                 created_at: worker_definition.inserted_at,
                 description: "long description",
                 label: "My Worker",
                 parameters: %{},
                 queue_name: "my_queue",
                 short_description: "short description",
                 version: "1.2.3"
               }
             ],
             total: 1
           }
  end
end
