defmodule StepFlow.Migration.CreateWorkfkowRights do
  use Ecto.Migration
  @moduledoc false
  def change do

    create table(:step_flow_workflow_rights) do
      add(:right, :string)
      add(:group, :string, default: "")

      add(
        :workflow_definition_id,
        references(:step_flow_workflow_definition, on_delete: :nothing)
      )

      timestamps()
    end

    create(index(:step_flow_workflow_rights, [:workflow_definition_id]))
  end
end
