defmodule StepFlow.RunWorkflows.MultipleJobsTest do
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
      identifier: "multiple_jobs_workflow",
      version_major: 0,
      version_minor: 1,
      version_micro: 3,
      reference: "some id",
      icon: "custom_icon",
      label: "Multiple jobs",
      tags: ["test"],
      parameters: [
        %{
          id: "segments",
          type: "array_of_media_segments",
          value: [
            %{
              start: 0,
              end: 999
            },
            %{
              start: 1000,
              end: 1999
            },
            %{
              start: 2000,
              end: 2999
            }
          ]
        }
      ],
      steps: [
        %{
          id: 0,
          name: "multiple_jobs_step",
          icon: "step_icon",
          label: "Multiple jobs step",
          multiple_jobs: "segments",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov"
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

    test "run a workflow with one step that generate multiple jobs" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 3)
      StepFlow.HelpersTest.check(workflow.id, "multiple_jobs_step", 3)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "multiple_jobs_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 3)
    end
  end
end
