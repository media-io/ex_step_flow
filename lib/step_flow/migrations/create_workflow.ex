defmodule StepFlow.Migration.CreateWorkflow do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_workflow) do
      add(:identifier, :string)
      add(:version_major, :integer)
      add(:version_minor, :integer)
      add(:version_micro, :integer)
      add(:tags, {:array, :string}, default: [])
      add(:reference, :string)
      add(:steps, {:array, :map}, default: [])
      add(:parameters, {:array, :map}, default: [])

      timestamps()
    end
  end
end
