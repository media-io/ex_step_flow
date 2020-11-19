defmodule StepFlow.Migration.CreateWorkfkowRights do
  use Ecto.Migration
  @moduledoc false
  def change do
    create table(:step_flow_right) do
      add(:action, :string)
      add(:groups, {:array, :string}, default: [])

      timestamps()
    end

    # Primary key and timestamps are not required if
    # using many_to_many without schemas
    create table(:step_flow_workflow_definition_right, primary_key: false) do
      add(:workflow_definition_id, references(:step_flow_workflow_definition))
      add(:right_id, references(:step_flow_right))
    end

    # Primary key and timestamps are not required if
    # using many_to_many without schemas
    create table(:step_flow_workflow_right, primary_key: false) do
      add(:workflow_id, references(:step_flow_workflow))
      add(:right_id, references(:step_flow_right))
    end
  end
end
