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
               data: [%StepFlow.WorkflowDefinitions.WorkflowDefinition{}],
               page: 0,
               size: 10,
               total: 1
             } = WorkflowDefinitions.list_workflow_definitions()
    end
  end
end
