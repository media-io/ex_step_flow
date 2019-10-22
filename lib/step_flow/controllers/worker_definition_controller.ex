defmodule StepFlow.WorkerDefinitionController do
  use Phoenix.Controller
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

  def show(conn, %{"id" => id}) do
    worker_definition =
      WorkerDefinitions.get_worker_definition!(id)

    conn
    |> put_view(StepFlow.WorkerDefinitionView)
    |> render("show.json", worker_definition: worker_definition)
  end
end
