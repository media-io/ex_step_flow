defmodule StepFlow.Workflows.StatusTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto
  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs
  alias StepFlow.Step
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Status
  require Logger

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
    {_conn, channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_test", 3)
    end)

    :ok
  end

  describe "workflows" do
    @valid_attrs %{
      schema_version: "1.8",
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "job_test",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: ["coucou.mov"]
            }
          ]
        },
        %{
          id: 1,
          required_to_start: [0],
          parent_ids: [0],
          name: "job_test",
          icon: "step_icon",
          label: "First parallel step",
          parameters: []
        },
        %{
          id: 2,
          required_to_start: [0],
          parent_ids: [0],
          name: "job_test",
          icon: "step_icon",
          label: "Second parallel step",
          parameters: []
        }
      ],
      rights: [
        %{
          action: "view",
          groups: ["user_view"]
        }
      ]
    }

    def workflow_fixture(attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Workflows.create_workflow()

      workflow
    end

    test "set_workflow_status with no job_status_id" do
      workflow = workflow_fixture()

      {:ok, status} = Status.set_workflow_status(workflow.id, :completed)

      assert status.state == :completed
    end

    test "set_workflow_status with existing job_status_id" do
      workflow = workflow_fixture()

      {:ok, "started"} = Step.start_next(workflow)
      [job | _] = StepFlow.HelpersTest.complete_jobs(workflow.id, 0)
      %{status: [job_status | _]} = Jobs.get_job_with_status!(job.id)

      {:ok, status} = Status.set_workflow_status(workflow.id, :completed, job_status.id)

      assert status.state == :completed
    end

    test "set_workflow_status with non existing job_status_id " do
      workflow = workflow_fixture()
      message = ~r/constraint error when attempting to insert struct/

      assert_raise Ecto.ConstraintError, message, fn ->
        Status.set_workflow_status(workflow.id, :completed, 1)
      end
    end

    test "get_last_workflow_status" do
      workflow = workflow_fixture()

      {:ok, _status} = Status.set_workflow_status(workflow.id, :pending)
      status = Status.get_last_workflow_status(workflow.id)
      assert status.state == :pending

      {:ok, _status} = Status.set_workflow_status(workflow.id, :completed)
      status = Status.get_last_workflow_status(workflow.id)
      assert status.state == :completed
    end

    test "get_last_jobs_status" do
      workflow = workflow_fixture()
      {:ok, _status} = Status.define_workflow_status(workflow.id, :created_workflow)

      {:ok, "started"} = Step.start_next(workflow)
      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 0, "completed")
      Status.set_workflow_status(workflow.id, :pending, job_status.id)

      {:ok, "started"} = Step.start_next(workflow)
      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 1, "error")
      Status.set_workflow_status(workflow.id, :error, job_status.id)

      before_retry = Status.get_last_jobs_status(workflow.id)

      assert Enum.at(before_retry, 0).state == :completed
      assert Enum.at(before_retry, 1).state == :error

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 1, "retrying")
      Status.set_workflow_status(workflow.id, :processing, job_status.id)

      after_retry = Status.get_last_jobs_status(workflow.id)

      assert Enum.at(after_retry, 0).state == :completed
      assert Enum.at(after_retry, 1).state == :retrying
      assert Enum.at(before_retry, 0).job_id == Enum.at(after_retry, 0).job_id
      assert Enum.at(before_retry, 1).job_id == Enum.at(after_retry, 1).job_id
    end

    test "define_workflow_status" do
      workflow = workflow_fixture()
      {:ok, status} = Status.define_workflow_status(workflow.id, :created_workflow)

      assert status.state == :pending

      {:ok, "started"} = Step.start_next(workflow)
      {:ok, progression} = StepFlow.HelpersTest.create_progression(workflow, 0, 0)
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_progression, progression)

      assert status.state == :processing

      {:ok, progression} = StepFlow.HelpersTest.create_progression(workflow, 0, 50)

      assert Status.define_workflow_status(workflow.id, :job_progression, progression) == nil

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 0, "error")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_error, job_status)

      assert status.state == :error

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 0, "retrying")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_retrying, job_status)

      assert status.state == :processing

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 0, "completed")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_completed, job_status)

      assert status.state == :pending

      {:ok, "started"} = Step.start_next(workflow)

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 1, "error")
      {:ok, status} = Status.define_workflow_status(workflow.id, :queue_not_found, job_status)

      assert status.state == :error

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 2, "error")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_error, job_status)

      assert status.state == :error

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 1, "retrying")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_retrying, job_status)

      assert status.state == :error

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 2, "retrying")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_retrying, job_status)

      assert status.state == :processing

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 1, "completed")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_completed, job_status)

      assert status.state == :processing

      {:ok, job_status} = StepFlow.HelpersTest.change_job_status(workflow, 2, "completed")
      {:ok, status} = Status.define_workflow_status(workflow.id, :job_completed, job_status)

      assert status.state == :pending

      {:ok, status} = Status.define_workflow_status(workflow.id, :completed_workflow)

      assert status.state == :completed
    end
  end
end
