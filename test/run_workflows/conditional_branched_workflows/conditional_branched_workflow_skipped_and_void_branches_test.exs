defmodule StepFlow.RunWorkflows.ConditionalBranchedWorkflowSkippedAndVoidTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    channel = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_queue_not_found", 2)
    end)

    :ok
  end

  describe "workflows" do
    @workflow_definition %{
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
          name: "my_first_step",
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
          id: 2,
          required_to_start: [0],
          parent_ids: [0],
          name: "second_parallel_step",
          icon: "step_icon",
          label: "Second parallel step",
          condition: "length(source_paths) > 2",
          parameters: []
        },
        %{
          id: 3,
          required_to_start: [2],
          parent_ids: [2],
          name: "second_parallel_step_two",
          icon: "step_icon",
          label: "Second parallel step 2",
          parameters: []
        },
        %{
          id: 4,
          required_to_start: [0, 3],
          parent_ids: [0, 3],
          name: "joined_last_step",
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

    test "run conditional branched skipped and void branch workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, 4)

      StepFlow.HelpersTest.check(workflow.id, 4)

      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step_two", 1)
      StepFlow.HelpersTest.check(workflow.id, 4)

      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step_two", 1)
      StepFlow.HelpersTest.check(workflow.id, "joined_last_step", 1)
      StepFlow.HelpersTest.check(workflow.id, 4)

      StepFlow.HelpersTest.complete_jobs(workflow.id, "joined_last_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 4)
    end
  end
end
