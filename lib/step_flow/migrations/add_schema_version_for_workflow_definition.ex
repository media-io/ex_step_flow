defmodule StepFlow.Migration.AddSchemaVersionForWorkflow do
  use Ecto.Migration
  @moduledoc false

  def change do
    alter table(:step_flow_workflow_definition) do
      add(:schema_version, :string, default: "1.8")
    end

    alter table(:step_flow_workflow) do
      add(:schema_version, :string, default: "1.8")
    end
  end
end
