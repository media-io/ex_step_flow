defmodule StepFlow.Amqp.ListJobsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
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

  test "list jobs with direct message queue" do
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

    job_query =
      StepFlow.Jobs.list_jobs(%{
        "direct_messaging_queue_name" => "direct_messaging_job_live"
      })
      |> Map.get(:data)
      |> List.first()

    assert job_query.id == job.id
  end
end
