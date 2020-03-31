defmodule StepFlow.WorkflowDefinitions do
  @moduledoc """
  The WorkflowDefinitions context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition
  require Logger

  @doc """
  Returns the list of Workflow Definitions.
  """
  def list_workflow_definitions(_params \\ %{}) do
    workflow_definitions = WorkflowDefinition.get_workflows()
    total = length(workflow_definitions)

    %{
      data: workflow_definitions,
      total: total,
      page: 1,
      size: total
    }
  end

  @doc """
  Returns the Workflow Definition.
  """
  def get_workflow_definition(workflow_identifier) do
    WorkflowDefinition.get_workflows()
    |> Enum.filter(fn workflow -> Map.get(workflow, "identifier") == workflow_identifier end)
    |> List.first()
  end
end
