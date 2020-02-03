defmodule StepFlow.Migration.CreateProgressions do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_progressions) do
      add(:datetime, :utc_datetime)
      add(:docker_container_id, :string)
      add(:progression, :integer)
      add(:job_id, references(:step_flow_jobs, on_delete: :nothing))

      timestamps()
    end

    create(index(:step_flow_progressions, [:job_id]))
  end
end
