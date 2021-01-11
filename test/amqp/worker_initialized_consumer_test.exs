defmodule StepFlow.Amqp.WorkerInitializedConsumerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Workflows

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
  end

  @workflow %{
    schema_version: "1.8",
    identifier: "id",
    version_major: 6,
    version_minor: 5,
    version_micro: 4,
    reference: "some id",
    steps: [],
    rights: [
      %{
        action: "create",
        groups: ["administrator"]
      }
    ]
  }

  test "consume well formed message with existing job" do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id,
        parameters: [
          %{
            id: "direct_messaging_queue_name",
            type: "string",
            value: "job_live"
          }
        ]
      })

    result =
      CommonEmitter.publish_json(
             "worker_initialized",
             0,
             %{
               job_id: job.id
             },
             "job_response"
           )

    :timer.sleep(1000)

    assert result == :ok

    assert StepFlow.HelpersTest.get_job_last_status(job.id).state == :ready_to_start
  end
end
