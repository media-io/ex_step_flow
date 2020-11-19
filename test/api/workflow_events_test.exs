defmodule StepFlow.Api.WorkflowEventsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Router
  alias StepFlow.Workflows
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  describe "workflow_events" do
    @authorized_user %{
      rights: [
        "administrator",
        "user"
      ]
    }

    @unauthorized_user %{
      rights: []
    }

    def workflow_fixture do
      {:ok, workflow} =
        Workflows.create_workflow(%{
          identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          version_major: 1,
          version_minor: 2,
          version_micro: 3,
          rights: [
            %{
              action: "abort",
              groups: ["administrator"]
            },
            %{
              action: "delete",
              groups: ["administrator"]
            },
            %{
              action: "retry",
              groups: ["administrator"]
            }
          ]
        })

      workflow
    end

    test "POST /workflows/:id/events event is not supported" do
      workflow = workflow_fixture()

      {status, _headers, _body} =
        conn(:post, "/workflows/#{workflow.id}/events", %{
          event: "event_that_does_not_exists"
        })
        |> assign(:current_user, @authorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 422
    end

    test "POST /workflows/:id/events abort valid with authorized user" do
      workflow = workflow_fixture()

      {status, _headers, _body} =
        conn(:post, "/workflows/#{workflow.id}/events", %{event: "abort"})
        |> assign(:current_user, @authorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
    end

    test "POST /workflows/:id/events abort valid with unauthorized user" do
      workflow = workflow_fixture()

      {status, _headers, _body} =
        conn(:post, "/workflows/#{workflow.id}/events", %{event: "abort"})
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
    end

    test "POST /workflows/:id/events retry valid (on failed job) with authorized user" do
      workflow = workflow_fixture()
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

      :timer.sleep(1000)

      # Retry workflow job

      {status, _headers, _body} =
        conn(:post, "/workflows/#{workflow.id}/events", %{event: "retry", job_id: job.id})
        |> assign(:current_user, @authorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      job = Jobs.get_job_with_status!(job.id)
      last_status = Status.get_last_status(job.status)

      assert last_status.state == :retrying
    end

    test "POST /workflows/:id/events retry valid (on failed job) with unauthorized user" do
      workflow = workflow_fixture()
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

      :timer.sleep(1000)

      # Retry workflow job

      {status, _headers, _body} =
        conn(:post, "/workflows/#{workflow.id}/events", %{event: "retry", job_id: job.id})
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
    end

    test "POST /workflows/:id/events retry invalid (on non-failed job)" do
      workflow = workflow_fixture()
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
        |> assign(:current_user, @authorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
      assert body == "illegal operation"
    end

    test "POST /workflows/:id/events delete valid with authorized user" do
      workflow = workflow_fixture()
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
        |> assign(:current_user, @authorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
    end

    test "POST /workflows/:id/events delete valid with unauthorized user" do
      workflow = workflow_fixture()
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
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
    end
  end
end
