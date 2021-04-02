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
      from(workflow_definition in WorkflowDefinition)
      |> check_rights(Map.get(params, "right_action"), Map.get(params, "rights"))
      |> filter_by_laber_or_identifier(Map.get(params, "search"))
      |> filter_by_versions(Map.get(params, "versions"))
      |> select_by_mode(Map.get(params, "mode"))

    total_query = from(item in subquery(query), select: count(item.id))

    total =
      Repo.all(total_query)
      |> List.first()

    query =
      from(
        workflow_definition in subquery(query),
        order_by: [
          desc: workflow_definition.version_major,
          desc: workflow_definition.version_minor,
          desc: workflow_definition.version_micro
        ],
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

  defp check_rights(query, right_action, user_rights) do
    case {right_action, user_rights} do
      {nil, _} ->
        query

      {_, nil} ->
        query

      {right_action, user_rights} ->
        from(
          workflow_definition in subquery(query),
          join: rights in assoc(workflow_definition, :rights),
          where: rights.action == ^right_action,
          where: fragment("?::varchar[] && ?::varchar[]", rights.groups, ^user_rights)
        )
    end
  end

  def filter_by_versions(query, versions) do
    case versions do
      ["latest"] ->
        from(
          workflow_definition in subquery(query),
          order_by: [
            desc: workflow_definition.version_major,
            desc: workflow_definition.version_minor,
            desc: workflow_definition.version_micro
          ],
          distinct: :identifier
        )

      versions when is_list(versions) and length(versions) != 0 ->
        from(
          workflow_definition in subquery(query),
          where:
            fragment(
              "concat(?, '.', ?, '.', ?) = ANY(?)",
              workflow_definition.version_major,
              workflow_definition.version_minor,
              workflow_definition.version_micro,
              ^versions
            )
        )

      _ ->
        query
    end
  end

  defp filter_by_laber_or_identifier(query, search) do
    case search do
      nil ->
        query

      search ->
        from(
          workflow_definition in subquery(query),
          where:
            ilike(workflow_definition.label, ^search) or
              ilike(workflow_definition.identifier, ^search)
        )
    end
  end

  defp select_by_mode(query, mode) do
    case mode do
      "simple" ->
        from(
          workflow_definition in subquery(query),
          select: %{
            id: workflow_definition.id,
            identifier: workflow_definition.identifier,
            label: workflow_definition.label,
            version_major: workflow_definition.version_major,
            version_minor: workflow_definition.version_minor,
            version_micro: workflow_definition.version_micro
          }
        )

      "full" ->
        query

      _ ->
        query
    end
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
end
