defmodule StepFlow.WorkflowsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Artifacts
  alias StepFlow.Repo
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
    {_conn, channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_test", 1)
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
        }
      ],
      rights: [
        %{
          action: "view",
          groups: ["user_view"]
        }
      ]
    }
    @update_attrs %{reference: "some updated id", steps: [%{action: "something"}]}
    @invalid_attrs %{reference: nil, flow: nil}

    def workflow_fixture(attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Workflows.create_workflow()

      workflow
    end

    test "list_workflows/0 returns all workflows" do
      workflow_fixture()
      |> Repo.preload([:artifacts, :jobs])

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows()

      assert page == 0
      assert size == 10
      assert total == 1
    end

    test "list_workflows/0 returns workflows with valid rights" do
      workflow_fixture()
      |> Repo.preload([:artifacts, :jobs])

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"rights" => ["user_view"]})

      assert page == 0
      assert size == 10
      assert total == 1
    end

    test "list_workflows/0 returns workflows with invalid rights" do
      workflow_fixture()

      assert Workflows.list_workflows(%{"rights" => ["user_create"]}) == %{
               data: [],
               page: 0,
               size: 10,
               total: 0
             }
    end

    test "list_workflows/0 returns workflows with different status" do
      workflow =
        workflow_fixture()
        |> Repo.preload([:artifacts, :jobs])

      Workflows.Status.set_workflow_status(workflow.id, :pending)

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"states" => ["pending"]})

      assert page == 0
      assert size == 10
      assert total == 1

      Workflows.Status.set_workflow_status(workflow.id, :error)

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"states" => ["error"]})

      assert page == 0
      assert size == 10
      assert total == 1

      Workflows.Status.set_workflow_status(workflow.id, :processing)

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"states" => ["processing"]})

      assert page == 0
      assert size == 10
      assert total == 1

      Workflows.Status.set_workflow_status(workflow.id, :completed)

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"states" => ["completed"]})

      assert page == 0
      assert size == 10
      assert total == 1
    end

    test "list_workflows/0 returns workflows with before date" do
      workflow_fixture()
      today = Date.utc_today() |> Date.to_iso8601()

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"before_date" => today})

      assert page == 0
      assert size == 10
      assert total == 1

      now = NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"before_date" => now})

      assert page == 0
      assert size == 10
      assert total == 1

      yesterday = Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"before_date" => yesterday})

      assert page == 0
      assert size == 10
      assert total == 0
    end

    test "list_workflows/0 returns workflows with after date" do
      workflow_fixture()
      yesterday = Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"after_date" => yesterday})

      assert page == 0
      assert size == 10
      assert total == 1

      yesterday_time =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-86_400, :second)
        |> NaiveDateTime.to_iso8601()

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"after_date" => yesterday_time})

      assert page == 0
      assert size == 10
      assert total == 1

      tomorrow = Date.utc_today() |> Date.add(1) |> Date.to_iso8601()

      %{
        page: page,
        size: size,
        total: total
      } = Workflows.list_workflows(%{"after_date" => tomorrow})

      assert page == 0
      assert size == 10
      assert total == 0
    end

    test "get_workflow!/1 returns the workflow with given id" do
      workflow =
        workflow_fixture()
        |> Repo.preload([:artifacts, :jobs])

      %{
        id: id,
        identifier: identifier,
        inserted_at: inserted_at
      } = Workflows.get_workflow!(workflow.id)

      assert id == workflow.id
      assert identifier == workflow.identifier
      assert inserted_at == workflow.inserted_at
    end

    test "create_workflow/1 with valid data creates a workflow" do
      assert {:ok, %Workflow{steps: [step]} = workflow} = Workflows.create_workflow(@valid_attrs)
      assert workflow.reference == "some id"
      assert step.icon == "step_icon"
    end

    test "create_workflow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Workflows.create_workflow(@invalid_attrs)
    end

    test "update_workflow/2 with valid data updates the workflow" do
      workflow = workflow_fixture()
      assert {:ok, workflow} = Workflows.update_workflow(workflow, @update_attrs)
      assert %Workflow{} = workflow
      assert workflow.reference == "some updated id"
      assert workflow.steps == [%{action: "something"}]
    end

    test "update_workflow/2 with invalid data returns error changeset" do
      workflow =
        workflow_fixture()
        |> Repo.preload([:artifacts, :jobs])

      assert {:error, %Ecto.Changeset{}} = Workflows.update_workflow(workflow, @invalid_attrs)

      %{
        id: id,
        identifier: identifier,
        inserted_at: inserted_at
      } = Workflows.get_workflow!(workflow.id)

      assert id == workflow.id
      assert identifier == workflow.identifier
      assert inserted_at == workflow.inserted_at
    end

    test "delete_workflow/1 deletes the workflow" do
      workflow = workflow_fixture()
      assert {:ok, %Workflow{}} = Workflows.delete_workflow(workflow)
      assert_raise Ecto.NoResultsError, fn -> Workflows.get_workflow!(workflow.id) end
    end

    test "change_workflow/1 returns a workflow changeset" do
      workflow = workflow_fixture()
      assert %Ecto.Changeset{} = Workflows.change_workflow(workflow)
    end

    @tag capture_log: true
    test "get_completed_statistics/1 returns finished workflow number" do
      workflow = workflow_fixture()
      :timer.sleep(1000)

      Artifacts.create_artifact(%{
        resources: %{},
        workflow_id: workflow.id
      })

      [%{count: count, duration: duration} | _] = Workflows.get_completed_statistics("day", -1)

      assert count == 1
      assert duration == 1
    end

    @tag capture_log: true
    test "get_completed_statistics/1 no artifacts" do
      workflow_fixture()

      assert [] == Workflows.get_completed_statistics("day", -1)
    end
  end
end
