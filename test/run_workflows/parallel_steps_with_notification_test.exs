defmodule StepFlow.RunWorkflows.ParallelStepsWithNotificationTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    channel = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_queue_not_found", 3)
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
      steps: [
        %{
          id: 0,
          name: "my_first_step",
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
          parameters: []
        },
        %{
          id: 2,
          required_to_start: [0],
          parent_ids: [0],
          name: "notification_step",
          mode: "notification",
          parameters: [
            %{
              id: "service",
              type: "string",
              value: "slack"
            },
            %{
              id: "channel",
              type: "string",
              value: "support"
            },
            %{
              id: "body",
              type: "template",
              value:
                "Workflow #<%= workflow_id %> - {step_name}\n\nFiles generated: <%= inspect source_paths %>"
            }
          ]
        },
        %{
          id: 3,
          required_to_start: [1, 2],
          parent_ids: [1, 2],
          name: "joined_last_step",
          parameters: []
        }
      ]
    }

    def workflow_fixture(workflow, attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(workflow)
        |> Workflows.create_workflow()

      workflow
    end

    test "run parallel steps on a same workflow" do
      workflow = workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "notification_step", 1)

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.complete_jobs(workflow.id, "first_parallel_step")

      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "notification_step", 1)

      {:ok, "still_processing"} = Step.start_next(workflow)

      # complete notifitication step because it's in error as we disables them for unit tests
      StepFlow.HelpersTest.complete_jobs(workflow.id, "notification_step")

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "first_parallel_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "notification_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "joined_last_step", 1)
      StepFlow.HelpersTest.check(workflow.id, 4)
    end
  end
end
