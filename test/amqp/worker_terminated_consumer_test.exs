defmodule StepFlow.Amqp.WorkerTerminatedConsumerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.LiveWorkers
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
        workflow_id: workflow.id
      })

    LiveWorkers.create_live_worker(%{
      job_id: job.id,
      direct_messaging_queue_name: "direct_messaging_job_live"
    })

    result =
      CommonEmitter.publish_json(
        "worker_terminated",
        0,
        %{
          job_id: job.id
        },
        "worker_response"
      )

    :timer.sleep(1000)

    live_worker = LiveWorkers.get_by(%{"job_id" => job.id})

    assert result == :ok
    assert live_worker.termination_date != nil
  end
end
