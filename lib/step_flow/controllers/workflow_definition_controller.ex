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

  def show(conn, %{"filename" => filename}) do
    case WorkflowDefinitions.get_workflow_definition(filename) do
      {:ok, workflow_definition} ->
        conn
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("show.json", workflow_definition: workflow_definition)

      {:error, errors} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("error.json", errors: errors)
    end
  end
end
