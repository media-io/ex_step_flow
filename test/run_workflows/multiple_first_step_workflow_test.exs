defmodule StepFlow.RunWorkflows.MultipleFirstStepWorkflowTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    {_conn, channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_test", 3)
    end)

    :ok
  end

  describe "workflows" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "multiple_first_step",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Multiple first step",
      tags: ["test"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "job_test",
          icon: "step_icon",
          label: "First step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov",
                "my_file_2.mov"
              ]
            }
          ]
        },
        %{
          id: 1,
          name: "job_test",
          icon: "step_icon",
          label: "Second step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_3.mov"
              ]
            }
          ]
        }
      ],
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ]
    }

    test "run workflow with 2 starting steps" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 3)
      StepFlow.HelpersTest.check(workflow.id, 0, 2)
      StepFlow.HelpersTest.check(workflow.id, 1, 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, 0)
      StepFlow.HelpersTest.complete_jobs(workflow.id, 1)

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 3)
    end
  end
end
