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
  end

  describe "workflows" do
    @valid_attrs %{
      schema_version: "1.8",
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [],
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
      workflow =
        workflow_fixture()
        |> Repo.preload([:artifacts, :jobs])

      assert Workflows.list_workflows() == %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             }
    end

    test "list_workflows/0 returns workflows with valid rights" do
      workflow =
        workflow_fixture()
        |> Repo.preload([:artifacts, :jobs])

      assert Workflows.list_workflows(%{"rights" => ["user_view"]}) == %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             }
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

    test "get_workflow!/1 returns the workflow with given id" do
      workflow =
        workflow_fixture()
        |> Repo.preload([:artifacts, :jobs])

      assert Workflows.get_workflow!(workflow.id) == workflow
    end

    test "create_workflow/1 with valid data creates a workflow" do
      assert {:ok, %Workflow{} = workflow} = Workflows.create_workflow(@valid_attrs)
      assert workflow.reference == "some id"
      assert workflow.steps == []
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
      assert workflow == Workflows.get_workflow!(workflow.id)
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
    test "get_statistics_per_identifier/1 returns finished workflow number" do
      workflow = workflow_fixture()
      :timer.sleep(1000)

      Artifacts.create_artifact(%{
        resources: %{},
        workflow_id: workflow.id
      })

      [%{count: count, duration: duration} | _] =
        Workflows.get_statistics_per_identifier("day", -1)

      assert count == 1
      assert duration == 1
    end

    @tag capture_log: true
    test "get_statistics_per_identifier/1 no artifacts" do
      workflow_fixture()

      assert [] == Workflows.get_statistics_per_identifier("day", -1)
    end
  end
end
