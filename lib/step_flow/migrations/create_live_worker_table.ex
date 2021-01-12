defmodule StepFlow.Migration.CreateLiveWorkerTable do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_live_workers) do
      add(:ips, {:array, :string}, default: [])
      add(:ports, {:array, :integer}, default: [])
      add(:instance_id, :string, default: "")
      add(:direct_messaging_queue_name, :string)
      add(:creation_date, :utc_datetime)
      add(:termination_date, :utc_datetime)
      add(:job_id, references(:step_flow_jobs, on_delete: :nothing))

      timestamps()
    end

    create(index(:step_flow_progressions, [:job_id]))
  end
end
