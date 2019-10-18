defmodule StepFlow.Migration.CreateStatus do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_status) do
      add(:state, :string)
      add(:description, :map, default: %{})
      add(:job_id, references(:step_flow_jobs, on_delete: :nothing))

      timestamps()
    end

    create(index(:step_flow_status, [:job_id]))
  end
end
