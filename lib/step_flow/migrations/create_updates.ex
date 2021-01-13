defmodule StepFlow.Migration.CreateUpdates do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_updates) do
      add(:datetime, :utc_datetime)
      add(:parameters, {:array, :map})
      add(:job_id, references(:step_flow_jobs, on_delete: :nothing))

      timestamps()
    end

    create(index(:step_flow_updates, [:job_id]))
  end
end
