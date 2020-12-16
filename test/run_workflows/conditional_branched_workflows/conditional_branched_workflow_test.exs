defmodule StepFlow.RunWorkflows.ConditionalBranchedWorkflowTest do
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
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Conditional branched steps",
      tags: ["test"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "job_test",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov"
              ]
            }
          ]
        },
        %{
          id: 1,
          required_to_start: [0],
          parent_ids: [0],
          name: "job_test",
          icon: "step_icon",
          label: "First parallel step",
          condition: "length(source_paths)==1",
          parameters: []
        },
        %{
          id: 2,
          required_to_start: [0],
          parent_ids: [0],
          name: "job_test",
          icon: "step_icon",
          label: "Second parallel step",
          condition: "length(source_paths) > 2",
          parameters: []
        },
        %{
          id: 3,
          required_to_start: [1, 2],
          parent_ids: [1, 2],
          name: "job_test",
          icon: "step_icon",
          label: "Joind last step",
          parameters: []
        }
      ],
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ]
    }

    test "run conditional branched workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, 0, 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, 0)

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1, 1)
      StepFlow.HelpersTest.check(workflow.id, 2, 1)

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.complete_jobs(workflow.id, 1)

      StepFlow.HelpersTest.check(workflow.id, 1, 1)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 0, 1)
      StepFlow.HelpersTest.check(workflow.id, 1, 1)
      StepFlow.HelpersTest.check(workflow.id, 2, 1)
      StepFlow.HelpersTest.check(workflow.id, 3, 1)
      StepFlow.HelpersTest.check(workflow.id, 4)

      StepFlow.HelpersTest.complete_jobs(workflow.id, 3)

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 4)
    end
  end
end
