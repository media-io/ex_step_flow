defmodule StepFlow.Amqp.ProgressionConsumerTest do
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
        groups: ["adminitstrator"]
      }
    ]
  }

  test "consume well formed message" do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id
      })

    {_, datetime, _} = DateTime.from_iso8601("2020-01-31T09:48:53Z")

    result =
      CommonEmitter.publish_json(
        "job_progression",
        0,
        %{
          job_id: job.id,
          datetime: datetime,
          docker_container_id: "unknown",
          progression: 50
        },
        "job_response"
      )

    :timer.sleep(1000)

    assert result == :ok
  end
end
