defmodule StepFlow.RunWorkflows.TwoStepsWorkflowTest do
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
      StepFlow.HelpersTest.consume_messages(channel, "job_test", 2)
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
      label: "Two steps workflow",
      tags: ["test"],
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
              value: ["coucou.mov"]
            }
          ]
        },
        %{
          id: 1,
          name: "job_test",
          icon: "step_icon",
          label: "My second step",
          parent_ids: [0],
          required_to_start: [0],
          parameters: []
        }
      ],
      parameters: [],
      rights: [
        %{
          action: "view",
          groups: []
        }
      ]
    }

    test "run simple workflow with 2 steps" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, 0, 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, 0)

      {:ok, "started"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 2)
      StepFlow.HelpersTest.check(workflow.id, 0, 1)
      StepFlow.HelpersTest.check(workflow.id, 1, 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, 1)

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 2)
    end
  end
end
