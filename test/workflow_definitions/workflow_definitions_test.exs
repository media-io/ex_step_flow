defmodule StepFlow.WorkflowDefinitionsTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.WorkflowDefinitions

  doctest StepFlow.WorkflowDefinitions

  setup do
    Sandbox.checkout(StepFlow.Repo)
  end

  describe "workflow_definitions" do
    test "list_workflow_definitions/0 returns workflow_definitions with rights" do
      assert %{
               data: [workflow, _],
               page: 0,
               size: 10,
               total: 2
             } =
               WorkflowDefinitions.list_workflow_definitions(%{
                 "rights" => ["administrator", "user"]
               })

      assert 5 == length(workflow.steps)
      assert 3 == length(workflow.start_parameters)
      assert 1 == length(workflow.parameters)
    end

    test "list_workflow_definitions/0 returns workflow_definitions with group unauthorized" do
      assert %{
               data: [],
               page: 0,
               size: 10,
               total: 0
             } = WorkflowDefinitions.list_workflow_definitions(%{"rights" => []})
    end
  end
end
