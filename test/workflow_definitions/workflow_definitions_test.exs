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
               WorkflowDefinitions.list_workflow_definitions(%{
                 "right_action" => "view",
                 "rights" => ["administrator_view"]
               })

      assert 0 == workflow.version_major
      assert 0 == workflow.version_minor
      assert 1 == workflow.version_micro

      result =
        WorkflowDefinitions.list_workflow_definitions(%{
          "right_action" => "view",
          "rights" => ["user_view"]
        })

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
      result =
        WorkflowDefinitions.list_workflow_definitions(%{"right_action" => "view", "rights" => []})

      assert %{
               data: [],
               page: 0,
               size: 10,
               total: 0
             } = result
    end

    test "list_workflow_definitions/0 returns workflow_definitions with version 0.0.1" do
      result =
        WorkflowDefinitions.list_workflow_definitions(%{
          "versions" => ["0.0.1"]
        })

      assert %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             } = result

      assert 0 == workflow.version_major
      assert 0 == workflow.version_minor
      assert 1 == workflow.version_micro
    end

    test "list_workflow_definitions/0 returns workflow_definitions with latest version" do
      result =
        WorkflowDefinitions.list_workflow_definitions(%{
          "versions" => ["latest"]
        })

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

    test "list_workflow_definitions/0 returns workflow_definitions with label matching 'Transcript%'" do
      result =
        WorkflowDefinitions.list_workflow_definitions(%{
          "search" => "Transcript%"
        })

      assert %{
               data: [_],
               page: 0,
               size: 10,
               total: 1
             } = result
    end

    test "list_workflow_definitions/0 returns workflow_definitions with simple mode" do
      result =
        WorkflowDefinitions.list_workflow_definitions(%{
          "mode" => "simple"
        })

      assert %{
               data: [workfklow | _],
               page: 0,
               size: 10,
               total: 2
             } = result

      assert Map.has_key?(workfklow, :identifier)
      assert not Map.has_key?(workfklow, :steps)
    end

    test "list_workflow_definitions/0 returns workflow_definitions with complex query" do
      result =
        WorkflowDefinitions.list_workflow_definitions(%{
          "mode" => "simple",
          "search" => "Transcript%",
          "versions" => ["0.0.1"]
        })

      assert %{
               data: [workflow],
               page: 0,
               size: 10,
               total: 1
             } = result

      assert not Map.has_key?(workflow, :steps)
      assert String.starts_with?(workflow.label, "Transcript")
      assert 0 == workflow.version_major
      assert 0 == workflow.version_minor
      assert 1 == workflow.version_micro
    end
  end
end
