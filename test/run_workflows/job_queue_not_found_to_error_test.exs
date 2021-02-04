defmodule StepFlow.RunWorkflows.JobQueueNotFoundToErrorTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
    {conn, _channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.close_amqp_connection(conn)
    end)

    :ok
  end

  @tag capture_log: true
  describe "workflows" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "status_steps",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Status steps",
      tags: ["test"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "job_with_queue_not_existing",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: ["my_file.mov"]
            }
          ]
        }
      ],
      rights: [
        %{
          action: "create",
          groups: ["administrator"]
        }
      ]
    }

    test "job queue not found to error" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      :timer.sleep(1000)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 0).queued == 0
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 0).processing == 0
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 0).errors == 1
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 0).completed == 0

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, 0, 1)
    end
  end
end
