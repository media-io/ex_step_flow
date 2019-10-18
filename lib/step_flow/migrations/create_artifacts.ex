defmodule StepFlow.Migration.CreateArtifacts do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:step_flow_artifacts) do
      add(:resources, :map)
      add(:workflow_id, references(:step_flow_workflow, on_delete: :nothing))

      timestamps()
    end
  end
end
