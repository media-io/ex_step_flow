defmodule StepFlow.WorkflowDefinitions do
  @moduledoc """
  The WorkflowDefinitions context.
  """

  import Ecto.Query, warn: false
  # alias StepFlow.Repo
  alias StepFlow.WorkflowDefinition

  @doc """
  Returns the list of Definitions.

  ## Examples

      iex> list_workflow_definitions()
      [%WorkflowDefinition{}, ...]

  """
  def list_workflow_definitions(params \\ %{}) do
    workflow_definition_directory =
      Application.get_env(:step_flow, :workflow_definition)

    workflow_definitions =
      workflow_definition_directory
      |> File.ls!()
      |> Enum.map(fn filename ->
        Path.join(workflow_definition_directory, filename)
        |> File.read!
        |> Jason.decode!
      end)
      |> Enum.filter(fn workflow_definition -> 
        WorkflowDefinition.valid?(workflow_definition)
      end)

    total = length(workflow_definitions)

    %{
      data: workflow_definitions,
      total: total,
      page: 1,
      size: total
    }
  end

  def get_workflow_definition(filename) do
    workflow_definition_directory =
      Application.get_env(:step_flow, :workflow_definition)


    workflow_definition =
      Path.join(workflow_definition_directory, filename)
      |> File.read!
      |> Jason.decode!

    if WorkflowDefinition.valid?(workflow_definition) do
      {:ok, workflow_definition}
    else
      WorkflowDefinition.validate(workflow_definition)
    end
  end
end
