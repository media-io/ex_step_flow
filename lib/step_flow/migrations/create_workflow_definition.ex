defmodule StepFlow.Migration.CreateWorkflowDefinition do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_workflow_definition) do
      add(:identifier, :string)
      add(:label, :string, default: "")
      add(:icon, :string, default: "")
      add(:version_major, :integer)
      add(:version_minor, :integer)
      add(:version_micro, :integer)
      add(:tags, {:array, :string}, default: [])
      add(:start_parameters, {:array, :map}, default: [])
      add(:parameters, {:array, :map}, default: [])
      add(:steps, {:array, :map}, default: [])

      timestamps()
    end

    create(
      unique_index(
        :step_flow_workflow_definition,
        [
          :identifier,
          :version_major,
          :version_minor,
          :version_micro
        ],
        name: :workflow_identifier_index
      )
    )
  end
end
