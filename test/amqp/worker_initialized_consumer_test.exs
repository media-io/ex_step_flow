defmodule StepFlow.Amqp.WorkerInitializedConsumerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.WorkerInitializedConsumer
  alias StepFlow.Jobs
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    {conn, channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.close_amqp_connection(conn)
    end)

    [channel: channel]
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

  test "consume well formed message with existing job", %{channel: channel} do
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

    tag = "live"

    result =
      WorkerInitializedConsumer.consume(
        channel,
        tag,
        false,
        %{
          "job_id" => job.id
        }
      )

    assert StepFlow.HelpersTest.get_job_last_status(job.id).state == :ready_to_start

    assert result == :ok
  end

  @tag capture_log: true
  test "consume badly formed message", %{channel: channel} do
    tag = "live"

    result = WorkerInitializedConsumer.consume(channel, tag, false, %{})

    assert result == :ok
  end
end
