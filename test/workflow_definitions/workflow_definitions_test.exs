defmodule StepFlow.WorkflowDefinitionsTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.WorkflowDefinitions

  doctest StepFlow.WorkflowDefinitions

  setup do
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  describe "workflow_definitions" do
    test "list_workflow_definitions/0 returns all workflow_definitions" do
      assert %{
               data: [workflow, _],
               page: 0,
               size: 10,
               total: 2
             } = WorkflowDefinitions.list_workflow_definitions()

      assert 5 == length(workflow.steps)
      assert 3 == length(workflow.start_parameters)
      assert 1 == length(workflow.parameters)
    end

    test "list_workflow_definitions/0 returns workflow_definitions with rights" do
      assert %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             } =
               WorkflowDefinitions.list_workflow_definitions(%{"rights" => ["administrator_view"]})

      assert 0 == workflow.version_major
      assert 0 == workflow.version_minor
      assert 1 == workflow.version_micro

      result = WorkflowDefinitions.list_workflow_definitions(%{"rights" => ["user_view"]})

      assert %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             } = result

      assert 0 == workflow.version_major
      assert 1 == workflow.version_minor
      assert 0 == workflow.version_micro
    end

    test "list_workflow_definitions/0 returns workflow_definitions with group unauthorized" do
      result = WorkflowDefinitions.list_workflow_definitions(%{"rights" => []})

      assert %{
               data: [],
               page: 0,
               size: 10,
               total: 0
             } = result
    end
  end
end
