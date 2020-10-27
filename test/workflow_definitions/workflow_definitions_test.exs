defmodule StepFlow.WorkflowDefinitionsTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.WorkflowDefinitions

  doctest StepFlow.WorkflowDefinitions

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  describe "workflow_definitions" do
    test "list_workflow_definitions/0 returns all workflow_definitions" do
      assert %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             } = WorkflowDefinitions.list_workflow_definitions()

      assert 5 == length(workflow.steps)
      assert 3 == length(workflow.start_parameters)
      assert 1 == length(workflow.parameters)
    end
  end
end
