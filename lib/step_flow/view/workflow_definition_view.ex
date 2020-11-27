defmodule StepFlow.WorkflowDefinitionView do
  use StepFlow, :view
  alias StepFlow.WorkflowDefinitionView

  def render("index.json", %{workflow_definitions: %{data: workflow_definitions, total: total}}) do
    %{
      data: render_many(workflow_definitions, WorkflowDefinitionView, "workflow_definition.json"),
      total: total
    }
  end

  def render("show.json", %{workflow_definition: workflow_definition}) do
    %{
      data:
        render_one(
          workflow_definition,
          WorkflowDefinitionView,
          "workflow_definition_with_steps.json"
        )
    }
  end

  def render("workflow_definition.json", %{workflow_definition: workflow_definition}) do
    %{
      schema_version: workflow_definition.schema_version,
      id: workflow_definition.id,
      identifier: workflow_definition.identifier,
      label: workflow_definition.label,
      icon: workflow_definition.icon,
      version_major: workflow_definition.version_major,
      version_minor: workflow_definition.version_minor,
      version_micro: workflow_definition.version_micro,
      tags: workflow_definition.tags,
      start_parameters: workflow_definition.start_parameters,
      parameters: workflow_definition.parameters
    }
  end

  def render("workflow_definition_with_steps.json", %{workflow_definition: workflow_definition}) do
    %{
      id: workflow_definition.id,
      identifier: workflow_definition.identifier,
      label: workflow_definition.label,
      icon: workflow_definition.icon,
      version_major: workflow_definition.version_major,
      version_minor: workflow_definition.version_minor,
      version_micro: workflow_definition.version_micro,
      tags: workflow_definition.tags,
      start_parameters: workflow_definition.start_parameters,
      parameters: workflow_definition.parameters,
      steps: workflow_definition.steps
    }
  end

  def render("error.json", %{errors: errors}) do
    %{
      errors: [
        %{
          reason: errors.reason,
          message: Map.get(errors, :message, "Incorrect parameters")
        }
      ]
    }
  end
end
