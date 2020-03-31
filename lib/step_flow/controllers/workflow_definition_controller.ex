defmodule StepFlow.WorkflowDefinitionController do
  use StepFlow, :controller
  use BlueBird.Controller

  alias StepFlow.WorkflowDefinitions

  action_fallback(StepFlow.FallbackController)

  def index(conn, params) do
    workflow_definitions = WorkflowDefinitions.list_workflow_definitions(params)

    conn
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("index.json", workflow_definitions: workflow_definitions)
  end

  def show(conn, %{"identifier" => identifier}) do
    case WorkflowDefinitions.get_workflow_definition(identifier) do
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("error.json",
          errors: %{reason: "Unable to locate workflow with this identifier"}
        )

      workflow_definition ->
        conn
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("show.json", workflow_definition: workflow_definition)
    end
  end
end
