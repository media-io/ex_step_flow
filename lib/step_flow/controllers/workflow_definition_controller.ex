defmodule StepFlow.WorkflowDefinitionController do
  use StepFlow, :controller
  use BlueBird.Controller

  import Plug.Conn

  alias StepFlow.Controller.Helpers
  alias StepFlow.WorkflowDefinitions
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition
  require Logger

  action_fallback(StepFlow.FallbackController)

  def index(%Plug.Conn{assigns: %{current_user: user}} = conn, params) do
    # Ajouter les droits à params

    params =
      params
      |> Map.put("rights", user.rights)

    workflow_definitions = WorkflowDefinitions.list_workflow_definitions(params)

    conn
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("index.json", workflow_definitions: workflow_definitions)
  end

  def index(conn, _) do
    conn
    |> put_status(403)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Forbidden to view workflows"}
    )
  end

  def show(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"identifier" => identifier}) do
    case WorkflowDefinitions.get_workflow_definition(identifier) do
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("error.json",
          errors: %{reason: "Unable to locate workflow with this identifier"}
        )

      workflow_definition ->
        if Helpers.has_right(workflow_definition, user, "view") do
          conn
          |> put_view(StepFlow.WorkflowDefinitionView)
          |> render("show.json", workflow_definition: workflow_definition)
        else
          conn
          |> put_status(:forbidden)
          |> put_view(StepFlow.WorkflowDefinitionView)
          |> render("error.json",
            errors: %{reason: "Forbidden to access workflow definition with this identifier"}
          )
        end
    end
  end

  def create(conn, _) do
    workflows = WorkflowDefinition.load_workflows_in_database()
    Logger.info("#{inspect(workflows)}")

    json(conn, %{})
  end
end
