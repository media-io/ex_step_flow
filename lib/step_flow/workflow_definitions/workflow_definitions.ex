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

    query =
      case Map.get(params, "rights") do
        nil ->
          from(workflow_definition in WorkflowDefinition)

        user_rights ->
          from(
            workflow_definition in WorkflowDefinition,
            join: rights in assoc(workflow_definition, :rights),
            where: rights.action == "view",
            where: fragment("?::varchar[] && ?::varchar[]", rights.groups, ^user_rights)
          )
      end

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
        preload: [:rights],
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

  @doc """
  Returns a list of identifiers for available workflows
  """
  def list_workflow_identifiers(action, user_rights \\ []) do
    query =
      from(
        workflow_definition in WorkflowDefinition,
        join: rights in assoc(workflow_definition, :rights),
        where: rights.action == ^action,
        where: fragment("?::varchar[] && ?::varchar[]", rights.groups, ^user_rights),
        distinct: workflow_definition.identifier,
        select: workflow_definition.identifier
      )

    Repo.all(query)
  end
end
