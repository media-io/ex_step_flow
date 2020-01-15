defmodule StepFlow.Api.WorkflowEventsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows
  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  def create_workflow do
    {:ok, workflow} = Workflows.create_workflow(%{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })

    workflow
  end

  test "POST /workflows/:id/events event is not supported" do
    workflow = create_workflow()

    {status, _headers, _body} =
      conn(:post, "/workflows/#{workflow.id}/events", %{
        event: "event_that_does_not_exists"
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 422
  end

  test "POST /workflows/:id/events abort valid" do
    workflow = create_workflow()

    {status, _headers, _body} =
      conn(:post, "/workflows/#{workflow.id}/events", %{event: "abort"})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
  end

  test "POST /workflows/:id/events retry valid (on failed job)" do
    workflow = create_workflow()
    step_id = 0
    action = "test_action"

    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: []
    }

    {result, job} = StepFlow.Jobs.create_job(job_params)

    assert result == :ok

    Status.set_job_status(job.id, :error)

    :timer.sleep(1000);

    # Retry workflow job
    {status, _headers, _body} =
      conn(:post, "/workflows/#{workflow.id}/events", %{event: "retry", job_id: job.id})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    job = Jobs.get_job_with_status!(job.id)
    last_status = Status.get_last_status(job.status)

    assert last_status.state == :retrying
  end

  test "POST /workflows/:id/events retry invalid (on non-failed job)" do
    workflow = create_workflow()
    step_id = 0
    action = "test_action"

    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: []
    }

    {result, job} = StepFlow.Jobs.create_job(job_params)

    assert result == :ok

    Status.set_job_status(job.id, :queued)
    Status.set_job_status(job.id, :error)
    Status.set_job_status(job.id, :processing)

    # Retry workflow job
    {status, _headers, body} =
      conn(:post, "/workflows/#{workflow.id}/events", %{event: "retry", job_id: job.id})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 403
    assert body == "illegal operation"
  end

  test "POST /workflows/:id/events delete valid" do
    workflow = create_workflow()
    step_id = 0
    action = "test_action"

    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: []
    }

    {result, _job} = StepFlow.Jobs.create_job(job_params)
    assert result == :ok
    {result, _job} = StepFlow.Jobs.create_job(job_params)
    assert result == :ok

    # Abort workflow
    {status, _headers, _body} =
      conn(:post, "/workflows/#{workflow.id}/events", %{event: "delete"})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
  end
end
