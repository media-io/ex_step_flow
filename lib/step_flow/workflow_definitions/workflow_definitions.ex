defmodule StepFlow.WorkflowDefinitions do
  @moduledoc """
  The WorkflowDefinitions context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition

  @doc """
  Returns the list of Workflow Definitions.
  """
  def list_workflow_definitions(_params \\ %{}) do
    workflow_definitions =
      WorkflowDefinition.get_workflow_definition_directories()
      |> Enum.map(fn directory ->
        directory
        |> File.ls!()
        |> Enum.map(fn filename ->
          Path.join(directory, filename)
          |> File.read!()
          |> Jason.decode!()
        end)
        |> Enum.filter(fn workflow_definition ->
          WorkflowDefinition.valid?(workflow_definition)
        end)
      end)
      |> List.flatten


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
  def get_workflow_definition(filename) do
    workflow_definition =
      WorkflowDefinition.get_workflow_definition_directories()
      |> Enum.map(fn directory -> Path.join(directory, filename) end)
      |> Enum.filter(fn full_path -> File.exists?(full_path) end)
      |> List.first()
      |> File.read!()
      |> Jason.decode!()

    if WorkflowDefinition.valid?(workflow_definition) do
      {:ok, workflow_definition}
    else
      WorkflowDefinition.validate(workflow_definition)
    end
  end
end
