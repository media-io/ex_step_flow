defmodule StepFlow.Api.WorkflowEventsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Router
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  test "POST /workflows/:id/events event is not supported" do
    # Create workflow
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    # Abort workflow
    {status, _headers, _body} =
      conn(:post, "/workflows/" <> workflow_id <> "/events", %{
        event: "event_that_does_not_exists"
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 422
  end

  test "POST /workflows/:id/events abort valid" do
    # Create workflow
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    # Abort workflow
    {status, _headers, _body} =
      conn(:post, "/workflows/" <> workflow_id <> "/events", %{event: "abort"})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
  end

  test "POST /workflows/:id/events retry valid (on failed job)" do
    # Create workflow
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    # Create job
    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    step_id = 0
    action = "test_action"

    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow_id,
      parameters: []
    }

    {result, job} = StepFlow.Jobs.create_job(job_params)

    assert result == :ok

    Status.set_job_status(job.id, Status.state_enum_label(:error))

    # Retry workflow job
    {status, _headers, _body} =
      conn(:post, "/workflows/" <> workflow_id <> "/events", %{event: "retry", job_id: job.id})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    job = Jobs.get_job_with_status!(job.id)
    last_status = Status.get_last_status(job.status)

    assert Status.state_enum_from_label(last_status.state) == :retrying
  end

  test "POST /workflows/:id/events retry invalid (on non-failed job)" do
    # Create workflow
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    # Create job
    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    step_id = 0
    action = "test_action"

    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow_id,
      parameters: []
    }

    {result, job} = StepFlow.Jobs.create_job(job_params)

    assert result == :ok

    Status.set_job_status(job.id, Status.state_enum_label(:queued))
    Status.set_job_status(job.id, Status.state_enum_label(:error))
    Status.set_job_status(job.id, Status.state_enum_label(:processing))

    # Retry workflow job
    {status, _headers, body} =
      conn(:post, "/workflows/" <> workflow_id <> "/events", %{event: "retry", job_id: job.id})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 403
    assert body == "illegal operation"
  end

  test "POST /workflows/:id/events delete valid" do
    # Create workflow
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    # Create job
    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    step_id = 0
    action = "test_action"

    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow_id,
      parameters: []
    }

    {result, _job} = StepFlow.Jobs.create_job(job_params)
    assert result == :ok
    {result, _job} = StepFlow.Jobs.create_job(job_params)
    assert result == :ok

    # Abort workflow
    {status, _headers, _body} =
      conn(:post, "/workflows/" <> workflow_id <> "/events", %{event: "delete"})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
  end
end
