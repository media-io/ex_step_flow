defmodule StepFlow.Migration.CreateJobs do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_jobs) do
      add(:name, :string)
      add(:step_id, :integer, default: 0)
      add(:parameters, {:array, :map}, default: [])
      add(:params, :map)

      add(:workflow_id, references(:step_flow_workflow, on_delete: :nothing))

      timestamps()
    end

    create(index(:step_flow_jobs, [:workflow_id]))
  end
end
