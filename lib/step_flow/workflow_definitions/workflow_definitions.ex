defmodule StepFlow.WorkflowDefinitions do
  @moduledoc """
  The WorkflowDefinitions context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition
  require Logger

  @doc """
  Returns the list of Workflow Definitions.
  """
  def list_workflow_definitions(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force()

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force()

    offset = page * size

    query = from(workflow_definition in WorkflowDefinition)

    total_query = from(item in subquery(query), select: count(item.id))

    total =
      Repo.all(total_query)
      |> List.first()

    query =
      from(
        workflow_definition in subquery(query),
        order_by: [desc: :inserted_at],
        offset: ^offset,
        limit: ^size
      )

    workflow_definitions = Repo.all(query)

    %{
      data: workflow_definitions,
      total: total,
      page: page,
      size: size
    }
  end

  @doc """
  Gets a single WorkflowDefinition.

  Raises `Ecto.NoResultsError` if the WorkflowDefinition does not exist.
  """
  def get_workflow_definition(identifier) do
    query =
      from(workflow_definition in WorkflowDefinition,
        where: workflow_definition.identifier == ^identifier,
        order_by: [
          desc: workflow_definition.version_major,
          desc: workflow_definition.version_minor,
          desc: workflow_definition.version_micro
        ],
        limit: 1
      )

    Repo.one(query)
  end
end
