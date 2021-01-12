defmodule StepFlow.LiveWorkers.LiveWorkerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.LiveWorkers
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

  test "create and get live worker structure" do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id,
        parameters: []
      })

    {_, live_worker} =
      LiveWorkers.create_live_worker(%{
        job_id: job.id,
        direct_messaging_queue_name: "direct_messaging_job_live"
      })

    assert live_worker.job_id == job.id
    assert live_worker.direct_messaging_queue_name == "direct_messaging_job_live"

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 1,
        workflow_id: workflow.id,
        parameters: []
      })

    {_, _} =
      LiveWorkers.create_live_worker(%{
        job_id: job.id,
        direct_messaging_queue_name: "direct_messaging_job_test"
      })

    live_worker = LiveWorkers.get_by(%{"job_id" => job.id})

    assert live_worker.job_id == job.id
    assert live_worker.direct_messaging_queue_name == "direct_messaging_job_test"
  end

  test "create and update live worker structure" do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id,
        parameters: []
      })

    {_, live_worker} =
      LiveWorkers.create_live_worker(%{
        job_id: job.id,
        direct_messaging_queue_name: "direct_messaging_job_test"
      })

    {_, live_worker} =
      LiveWorkers.update_live_worker(live_worker, %{
        "direct_messaging_queue_name" => "direct_messaging_job_toto"
      })

    assert live_worker.job_id == job.id
    assert live_worker.direct_messaging_queue_name == "direct_messaging_job_toto"
  end

  test "changeset live worker structure" do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id,
        parameters: []
      })

    {_, live_worker} =
      LiveWorkers.create_live_worker(%{
        job_id: job.id,
        direct_messaging_queue_name: "direct_messaging_job_test"
      })

    LiveWorkers.delete_live_worker(live_worker)

    live_worker = LiveWorkers.get_by(%{"job_id" => job.id})

    assert live_worker == nil
  end
end
