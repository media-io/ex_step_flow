defmodule StepFlow.WorkflowController do
  use StepFlow, :controller
  use BlueBird.Controller

  require Logger

  alias StepFlow.Repo
  alias StepFlow.Step
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow

  action_fallback(StepFlow.FallbackController)

  def index(conn, params) do
    workflows = Workflows.list_workflows(params)

    conn
    |> put_view(StepFlow.WorkflowView)
    |> render("index.json", workflows: workflows)
  end

  def create(conn, workflow_params) do
    case Workflows.create_workflow(workflow_params) do
      {:ok, %Workflow{} = workflow} ->
        Step.start_next(workflow)

        StepFlow.Notification.send("new_workflow", %{workflow_id: workflow.id})

        conn
        |> put_status(:created)
        |> put_view(StepFlow.WorkflowView)
        |> render("created.json", workflow: workflow)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def create_workflow(conn, %{"workflow_identifier" => identifier} = workflow_params) do
    case StepFlow.WorkflowDefinitions.get_workflow_definition(identifier) do
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("error.json",
          errors: %{workflow_identifier: "Unable to locate workflow with this identifier"}
        )

      workflow_definition ->
        workflow_description =
          workflow_definition
          |> Map.put(:reference, Map.get(workflow_params, "reference"))
          |> Map.put(
            :parameters,
            merge_parameters(
              StepFlow.Map.get_by_key_or_atom(workflow_definition, :parameters),
              Map.get(workflow_params, "parameters", %{})
            )
          )
          |> Map.from_struct()

        create(conn, workflow_description)
    end
  end

  def create_workflow(conn, _workflow_params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{workflow_identifier: "Missing Workflow identifier parameter"}
    )
  end

  defp merge_parameters(parameters, request_parameters, result \\ [])
  defp merge_parameters([], _request_parameters, result), do: result

  defp merge_parameters([parameter | tail], request_parameters, result) do
    result =
      case Map.get(request_parameters, Map.get(parameter, "id")) do
        nil ->
          List.insert_at(result, -1, parameter)

        parameter_value ->
          List.insert_at(result, -1, Map.put(parameter, "value", parameter_value))
      end

    merge_parameters(tail, request_parameters, result)
  end

  def show(conn, %{"id" => id}) do
    workflow =
      Workflows.get_workflow!(id)
      |> Repo.preload(:jobs)

    conn
    |> put_view(StepFlow.WorkflowView)
    |> render("show.json", workflow: workflow)
  end

  def get(conn, %{"identifier" => workflow_identifier} = _params) do
    workflow =
      case workflow_identifier do
        _ -> %{}
      end

    conn
    |> json(workflow)
  end

  def get(conn, _params) do
    conn
    |> json(%{})
  end

  def statistics(conn, params) do
    scale = Map.get(params, "scale", "hour")
    stats = Workflows.get_workflow_history(%{scale: scale})

    conn
    |> json(%{
      data: stats
    })
  end

  def update(conn, %{"id" => id, "workflow" => workflow_params}) do
    workflow = Workflows.get_workflow!(id)

    with {:ok, %Workflow{} = workflow} <- Workflows.update_workflow(workflow, workflow_params) do
      conn
      |> put_view(StepFlow.WorkflowView)
      |> render("show.json", workflow: workflow)
    end
  end

  def delete(conn, %{"id" => id}) do
    workflow = Workflows.get_workflow!(id)

    with {:ok, %Workflow{}} <- Workflows.delete_workflow(workflow) do
      send_resp(conn, :no_content, "")
    end
  end
end
