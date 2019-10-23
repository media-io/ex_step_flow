defmodule StepFlow.RunWorkflowTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # channel = StepFlow.HelpersTest.get_amqp_connection()

    # on_exit(fn ->
    # )
    :ok
  end

  describe "workflows" do
    @simple_workflow %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          parameters: [
            %{
              id: "source_paths",
              value: "my_file.mov"
            }
          ]
        }
      ],
      parameters: []
    }

    @two_steps_workflow %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          parameters: [
            %{
              id: "source_paths",
              value: "my_file.mov"
            }
          ]
        },
        %{
          id: 1,
          name: "my_second_step",
          parent_ids: [0],
          required: [0],
          parameters: []
        }
      ],
      parameters: []
    }

    def workflow_fixture(workflow, attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(workflow)
        |> Workflows.create_workflow()

      workflow
    end

    test "run simple workflow with 1 step" do
      workflow = workflow_fixture(@simple_workflow)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 1)
    end

    test "run simple workflow with 2 steps" do
      workflow = workflow_fixture(@two_steps_workflow)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "started"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 2)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "my_second_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_second_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 2)
    end
  end
end
