defmodule StepFlow.RunWorkflows.ParallelStepsWithNotificationTest do
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
      StepFlow.HelpersTest.consume_messages(channel, "job_queue_not_found", 3)
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
      label: "Parallel steps with notification",
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
          name: "notification_step",
          mode: "notification",
          icon: "step_icon",
          label: "Notification step",
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
          icon: "step_icon",
          label: "Joined last step",
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

    test "run parallel steps on a same workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

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
