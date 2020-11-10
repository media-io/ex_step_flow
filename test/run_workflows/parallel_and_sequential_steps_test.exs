defmodule StepFlow.RunWorkflows.ParallelSequentialStepsTest do
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
      StepFlow.HelpersTest.consume_messages(channel, "job_queue_not_found", 5)
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
      label: "Parallel steps",
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
          id: 1,
          required_to_start: [0],
          parent_ids: [0],
          name: "first_parallel_step",
          icon: "step_icon",
          label: "First parallel step",
          parameters: []
        },
        %{
          id: 2,
          required_to_start: [0],
          parent_ids: [0],
          name: "second_parallel_step",
          icon: "step_icon",
          label: "Second parallel step",
          parameters: []
        },
        %{
          id: 3,
          required_to_start: [1],
          parent_ids: [1],
          name: "third_parallel_step",
          icon: "step_icon",
          label: "Third parallel step",
          parameters: []
        },
        %{
          id: 4,
          required_to_start: [2, 3],
          parent_ids: [2, 3],
          name: "joined_last_step",
          icon: "step_icon",
          label: "Joind last step",
          parameters: []
        }
      ],
      rights: %{
        view: [],
        create: [],
        retry: [],
        abort: [],
        delete: []
      }
    }

    test "run parallel and sequential steps on a same workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step", 1)

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.complete_jobs(workflow.id, "first_parallel_step")

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "third_parallel_step", 1)

      StepFlow.HelpersTest.complete_jobs(workflow.id, "second_parallel_step")
      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "third_parallel_step", 1)

      StepFlow.HelpersTest.complete_jobs(workflow.id, "third_parallel_step")
      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "second_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "third_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "joined_last_step", 1)
      StepFlow.HelpersTest.check(workflow.id, 5)
    end
  end
end
