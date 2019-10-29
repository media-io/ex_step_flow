defmodule StepFlow.WorkerDefinitionController do
  use StepFlow, :controller
  use BlueBird.Controller

  alias StepFlow.WorkerDefinitions
  alias StepFlow.WorkerDefinitions.WorkerDefinition

  action_fallback(StepFlow.FallbackController)

  def index(conn, params) do
    worker_definitions = WorkerDefinitions.list_worker_definitions(params)

    conn
    |> put_view(StepFlow.WorkerDefinitionView)
    |> render("index.json", worker_definitions: worker_definitions)
  end

  def create(conn, workflow_params) do
    case WorkerDefinitions.create_worker_definition(workflow_params) do
      {:ok, %WorkerDefinition{} = worker_definition} ->
        conn
        |> put_status(:created)
        |> put_view(StepFlow.WorkerDefinitionView)
        |> render("show.json", worker_definition: worker_definition)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    worker_definition = WorkerDefinitions.get_worker_definition!(id)

    conn
    |> put_view(StepFlow.WorkerDefinitionView)
    |> render("show.json", worker_definition: worker_definition)
  end
end
