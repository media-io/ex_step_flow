defmodule StepFlow.Amqp.ProgressionConsumerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.ProgressionConsumer
  alias StepFlow.Jobs
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    channel = StepFlow.HelpersTest.get_amqp_connection()

    [channel: channel]
  end

  @workflow %{
    identifier: "id",
    version_major: 6,
    version_minor: 5,
    version_micro: 4,
    reference: "some id",
    steps: []
  }

  test "consume well formed message", %{channel: channel} do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id
      })

    tag = "acs"
    {_, datetime, _} = DateTime.from_iso8601("2020-01-31T09:48:53Z")

    result =
      ProgressionConsumer.consume(
        channel,
        tag,
        false,
        %{
          "job_id" => job.id,
          "datetime" => datetime,
          "docker_container_id" => "unknown",
          "progression" => 50
        }
      )

    assert result == :ok
  end

  @tag capture_log: true
  test "consume badly formed message", %{channel: channel} do
    tag = "acs"

    result = ProgressionConsumer.consume(channel, tag, false, %{})

    assert result == :ok
  end
end
