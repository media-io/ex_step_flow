defmodule StepFlow.WorkerDefinitionView do
  use StepFlow, :view
  alias StepFlow.WorkerDefinitionView

  def render("index.json", %{worker_definitions: %{data: worker_definitions, total: total}}) do
    %{
      data: render_many(worker_definitions, WorkerDefinitionView, "worker_definition.json"),
      total: total
    }
  end

  def render("show.json", %{worker_definition: worker_definition}) do
    %{data: render_one(worker_definition, WorkerDefinitionView, "worker_definition.json")}
  end

  def render("worker_definition.json", %{worker_definition: worker_definition}) do
    %{
      id: worker_definition.id,
      queue_name: worker_definition.queue_name,
      label: worker_definition.label,
      short_description: worker_definition.short_description,
      description: worker_definition.description,
      version: worker_definition.version,
      parameters: worker_definition.parameters,
      created_at: worker_definition.inserted_at
    }
  end
end
